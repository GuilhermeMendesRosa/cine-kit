import AppKit
import CineKitCore
import SwiftUI

/// The emulator's own framebuffer, shared with `-share-vid` (ADR 0009). Unlike a capture inside Android,
/// it also shows windows with FLAG_SECURE.
@MainActor
final class EmulatorFrameSource {
    enum SourceError: Error {
        case unavailable
    }

    private let region: UnsafeRawBufferPointer
    private var lastFrame: UInt32?

    init() throws {
        // shm_open is variadic in C; the mode argument only matters with O_CREAT.
        let fd = EmulatorFrameHeader.sharedMemoryName.withCString { Self.shmOpen($0, O_RDONLY) }
        guard fd >= 0 else { throw SourceError.unavailable }
        defer { close(fd) }
        var info = stat()
        guard fstat(fd, &info) == 0, let base = mmap(nil, Int(info.st_size), PROT_READ, MAP_SHARED, fd, 0), base != MAP_FAILED else {
            throw SourceError.unavailable
        }
        region = UnsafeRawBufferPointer(start: base, count: Int(info.st_size))
        guard EmulatorFrameHeader(region, regionSize: region.count) != nil else { throw SourceError.unavailable }
    }

    isolated deinit {
        munmap(UnsafeMutableRawPointer(mutating: region.baseAddress), region.count)
    }

    /// The current frame, or nil when it did not change since the last call.
    func nextImage() -> CGImage? {
        guard let header = EmulatorFrameHeader(region, regionSize: region.count), header.frameNumber != lastFrame else { return nil }
        let pixels = Data(bytes: region.baseAddress! + EmulatorFrameHeader.size, count: header.width * header.height * 4)
        // The emulator may have written a new frame during the copy; drop the torn one and retry on the next tick.
        guard EmulatorFrameHeader(region, regionSize: region.count)?.frameNumber == header.frameNumber,
              let provider = CGDataProvider(data: pixels as CFData) else { return nil }
        lastFrame = header.frameNumber
        return CGImage(
            width: header.width, height: header.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: header.width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent
        )
    }

    private static let shmOpen = unsafeBitCast(
        dlsym(UnsafeMutableRawPointer(bitPattern: -2), "shm_open"), // RTLD_DEFAULT
        to: (@convention(c) (UnsafePointer<CChar>, Int32) -> Int32).self
    )
}

struct EmulatorFrameView: NSViewRepresentable {
    let source: EmulatorFrameSource

    func makeNSView(context: Context) -> FrameView {
        FrameView(source: source)
    }

    func updateNSView(_ view: FrameView, context: Context) {}

    /// Polls the shared framebuffer once per screen refresh.
    final class FrameView: NSView {
        private let source: EmulatorFrameSource
        private var displayLink: CADisplayLink?

        init(source: EmulatorFrameSource) {
            self.source = source
            super.init(frame: .zero)
            wantsLayer = true
            layer?.backgroundColor = .black
            layer?.contentsGravity = .resizeAspect
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            displayLink?.invalidate()
            displayLink = nil
            guard window != nil else { return }
            let link = displayLink(target: self, selector: #selector(tick))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }

        @objc private func tick() {
            if let image = source.nextImage() { layer?.contents = image }
        }
    }
}
