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
    /// Of the last frame read, in Android pixels.
    private(set) var frameSize: (width: Int, height: Int)?

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
        frameSize = (header.width, header.height)
        let pixels = Data(bytes: region.baseAddress! + EmulatorFrameHeader.size, count: header.width * header.height * 4)
        // The emulator may have written a new frame during the copy; drop the torn one and retry on the next tick.
        guard EmulatorFrameHeader(region, regionSize: region.count)?.frameNumber == header.frameNumber,
              let provider = CGDataProvider(data: pixels as CFData) else { return nil }
        lastFrame = header.frameNumber
        return CGImage(
            width: header.width, height: header.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: header.width * 4,
            // The pixels are BGRA in memory, which is 32-bit little-endian with the alpha first.
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue),
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
    let onControl: (ScrcpyControlMessage) -> Void

    func makeNSView(context: Context) -> FrameView {
        FrameView(source: source, onControl: onControl)
    }

    func updateNSView(_ view: FrameView, context: Context) {}

    /// Polls the shared framebuffer once per screen refresh and turns the Mac mouse into touches (ADR 0012).
    final class FrameView: NSView {
        // Scroll deltas per Android scroll step: trackpads and the remote send precise pixel deltas, wheels send lines.
        private static let preciseScrollStep = 20.0
        private static let wheelScrollStep = 1.0

        private let source: EmulatorFrameSource
        private let onControl: (ScrcpyControlMessage) -> Void
        private var displayLink: CADisplayLink?

        init(source: EmulatorFrameSource, onControl: @escaping (ScrcpyControlMessage) -> Void) {
            self.source = source
            self.onControl = onControl
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

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        override func mouseDown(with event: NSEvent) { touch(.down, event) }

        override func mouseDragged(with event: NSEvent) { touch(.move, event) }

        override func mouseUp(with event: NSEvent) { touch(.up, event) }

        override func scrollWheel(with event: NSEvent) {
            guard let (point, size) = devicePoint(event) else { return }
            let step = event.hasPreciseScrollingDeltas ? Self.preciseScrollStep : Self.wheelScrollStep
            onControl(.injectScroll(
                x: point.x, y: point.y, width: size.width, height: size.height,
                horizontal: Float(event.scrollingDeltaX / step), vertical: Float(event.scrollingDeltaY / step)
            ))
        }

        private func touch(_ action: ScrcpyControlMessage.TouchAction, _ event: NSEvent) {
            guard let (point, size) = devicePoint(event) else { return }
            onControl(.injectTouch(action: action, x: point.x, y: point.y, width: size.width, height: size.height))
        }

        /// Nil before the first frame or on the bars around the image.
        private func devicePoint(_ event: NSEvent) -> (point: (x: Int32, y: Int32), size: (width: UInt16, height: UInt16))? {
            guard let frame = source.frameSize else { return nil }
            let location = convert(event.locationInWindow, from: nil)
            guard let point = EmulatorPointer.devicePoint(
                // Android's origin is at the top left; flipping the view instead could flip the video layer.
                x: location.x, y: bounds.height - location.y, viewWidth: bounds.width, viewHeight: bounds.height,
                frameWidth: frame.width, frameHeight: frame.height
            ) else { return nil }
            return (point, (UInt16(frame.width), UInt16(frame.height)))
        }
    }
}
