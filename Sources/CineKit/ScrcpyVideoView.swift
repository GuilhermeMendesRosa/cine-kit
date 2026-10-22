import AVFoundation
import SwiftUI

/// Shows the H.264 stream from `ScrcpyClient`; the layer decodes with VideoToolbox.
struct ScrcpyVideoView: NSViewRepresentable {
    let renderer: H264Renderer

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.layer = renderer.layer
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {}
}

/// Turns Annex B packets into sample buffers. It exists before the view so no packet is lost while the screen switches.
@MainActor
final class H264Renderer {
    let layer = AVSampleBufferDisplayLayer()
    private var format: CMVideoFormatDescription?

    init() {
        layer.videoGravity = .resizeAspect
        layer.backgroundColor = .black
    }

    func enqueue(_ packet: Data, isConfig: Bool) {
        let units = Self.nalUnits(in: packet)
        if isConfig {
            format = Self.format(fromParameterSets: units)
            return
        }
        guard let format, let sample = Self.sampleBuffer(units, format: format) else { return }
        if layer.sampleBufferRenderer.status == .failed { layer.sampleBufferRenderer.flush() }
        layer.sampleBufferRenderer.enqueue(sample)
    }

    /// Splits on `00 00 01` start codes (the 4-byte form leaves a trailing zero, which is dropped).
    private static func nalUnits(in data: Data) -> [Data] {
        let bytes = [UInt8](data)
        var starts: [Int] = []
        var index = 0
        while index + 2 < bytes.count {
            if bytes[index] == 0, bytes[index + 1] == 0, bytes[index + 2] == 1 {
                starts.append(index + 3)
                index += 3
            } else {
                index += 1
            }
        }
        return starts.enumerated().map { offset, start in
            var end = offset + 1 < starts.count ? starts[offset + 1] - 3 : bytes.count
            while end > start, bytes[end - 1] == 0 { end -= 1 }
            return Data(bytes[start..<end])
        }
    }

    private static func format(fromParameterSets units: [Data]) -> CMVideoFormatDescription? {
        // NAL unit type 7 is SPS and 8 is PPS.
        guard let sps = units.first(where: { $0.first.map { $0 & 0x1F } == 7 }),
              let pps = units.first(where: { $0.first.map { $0 & 0x1F } == 8 }) else { return nil }
        var format: CMVideoFormatDescription?
        sps.withUnsafeBytes { spsBytes in
            pps.withUnsafeBytes { ppsBytes in
                let pointers = [spsBytes.bindMemory(to: UInt8.self).baseAddress!, ppsBytes.bindMemory(to: UInt8.self).baseAddress!]
                let sizes = [sps.count, pps.count]
                _ = CMVideoFormatDescriptionCreateFromH264ParameterSets(
                    allocator: nil, parameterSetCount: 2, parameterSetPointers: pointers,
                    parameterSetSizes: sizes, nalUnitHeaderLength: 4, formatDescriptionOut: &format
                )
            }
        }
        return format
    }

    /// Rewrites the units with 4-byte big-endian length prefixes (AVCC), as the format description declares.
    private static func sampleBuffer(_ units: [Data], format: CMVideoFormatDescription) -> CMSampleBuffer? {
        var avcc = Data()
        for unit in units {
            avcc.append(contentsOf: withUnsafeBytes(of: UInt32(unit.count).bigEndian, Array.init))
            avcc.append(unit)
        }
        var block: CMBlockBuffer?
        guard CMBlockBufferCreateWithMemoryBlock(
            allocator: nil, memoryBlock: nil, blockLength: avcc.count, blockAllocator: nil,
            customBlockSource: nil, offsetToData: 0, dataLength: avcc.count, flags: 0, blockBufferOut: &block
        ) == noErr, let block else { return nil }
        let copied = avcc.withUnsafeBytes {
            CMBlockBufferReplaceDataBytes(with: $0.baseAddress!, blockBuffer: block, offsetIntoDestination: 0, dataLength: avcc.count)
        }
        guard copied == noErr else { return nil }
        var sample: CMSampleBuffer?
        var size = avcc.count
        guard CMSampleBufferCreateReady(
            allocator: nil, dataBuffer: block, formatDescription: format, sampleCount: 1,
            sampleTimingEntryCount: 0, sampleTimingArray: nil, sampleSizeEntryCount: 1,
            sampleSizeArray: &size, sampleBufferOut: &sample
        ) == noErr, let sample else { return nil }
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sample, createIfNecessary: true) as? [NSMutableDictionary] {
            attachments.first?[kCMSampleAttachmentKey_DisplayImmediately] = true
        }
        return sample
    }
}
