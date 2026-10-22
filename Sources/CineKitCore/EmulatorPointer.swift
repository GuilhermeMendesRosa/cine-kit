/// Maps a point on the video view to the Android pixel under it (ADR 0012).
public enum EmulatorPointer {
    /// The view shows the frame aspect-fit, both with the origin at the top left; nil on the bars or outside the view.
    public static func devicePoint(
        x: Double, y: Double, viewWidth: Double, viewHeight: Double, frameWidth: Int, frameHeight: Int
    ) -> (x: Int32, y: Int32)? {
        let scale = min(viewWidth / Double(frameWidth), viewHeight / Double(frameHeight))
        let deviceX = (x - (viewWidth - Double(frameWidth) * scale) / 2) / scale
        let deviceY = (y - (viewHeight - Double(frameHeight) * scale) / 2) / scale
        guard (0..<Double(frameWidth)).contains(deviceX), (0..<Double(frameHeight)).contains(deviceY) else { return nil }
        return (Int32(deviceX), Int32(deviceY))
    }
}
