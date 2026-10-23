/// A button of the web remote, as sent in `POST /api/press` (ADR 0003, protocol v1).
public enum RemoteButton: String, Sendable {
    case up, down, left, right, ok, back, home, playPause, volumeUp, volumeDown, mute, delete, power
}
