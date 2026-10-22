/// A touchpad event of the web remote, as sent in `POST /api/pointer` (ADR 0012).
public enum RemotePointerEvent: Equatable, Sendable, Decodable {
    /// Larger deltas are rejected: no phone gesture produces them.
    static let maxDelta = 4000.0

    case move(dx: Double, dy: Double)
    case scroll(dx: Double, dy: Double)
    /// A point of the screen as a fraction 0...1 of its width and height, from the top left (ADR 0015).
    case moveTo(x: Double, y: Double)
    case click

    private enum CodingKeys: String, CodingKey {
        case type, dx, dy, x, y
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        if type == "click" {
            self = .click
            return
        }
        if type == "moveTo" {
            let x = try container.decode(Double.self, forKey: .x)
            let y = try container.decode(Double.self, forKey: .y)
            guard [x, y].allSatisfy({ $0.isFinite && (0...1).contains($0) }) else {
                throw DecodingError.dataCorruptedError(forKey: .x, in: container, debugDescription: "Point out of range")
            }
            self = .moveTo(x: x, y: y)
            return
        }
        let dx = try container.decode(Double.self, forKey: .dx)
        let dy = try container.decode(Double.self, forKey: .dy)
        guard [dx, dy].allSatisfy({ $0.isFinite && abs($0) <= Self.maxDelta }) else {
            throw DecodingError.dataCorruptedError(forKey: .dx, in: container, debugDescription: "Delta out of range")
        }
        switch type {
        case "move": self = .move(dx: dx, dy: dy)
        case "scroll": self = .scroll(dx: dx, dy: dy)
        default: throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type \(type)")
        }
    }
}
