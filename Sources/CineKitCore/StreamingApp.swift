import Foundation

public struct StreamingApp: Codable, Identifiable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var url: URL
    public var colorHex: String
    public var imageFileName: String?
    public var isDefault: Bool
    /// Whether the web remote plays its click sound while this app is open (ADR 0015).
    public var remoteClickSound: Bool

    public init(
        id: String, name: String, url: URL, colorHex: String, imageFileName: String? = nil, isDefault: Bool, remoteClickSound: Bool = true
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.colorHex = colorHex
        self.imageFileName = imageFileName
        self.isDefault = isDefault
        self.remoteClickSound = remoteClickSound
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, url, colorHex, imageFileName, isDefault, remoteClickSound
    }

    /// Apps saved before the click sound existed come with it on.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        url = try container.decode(URL.self, forKey: .url)
        colorHex = try container.decode(String.self, forKey: .colorHex)
        imageFileName = try container.decodeIfPresent(String.self, forKey: .imageFileName)
        isDefault = try container.decode(Bool.self, forKey: .isDefault)
        remoteClickSound = try container.decodeIfPresent(Bool.self, forKey: .remoteClickSound) ?? true
    }

    /// Android apps are stored as `android-app://<package>` (ADR 0004).
    public var androidPackage: String? {
        url.scheme == "android-app" ? url.host() : nil
    }

    public static func android(package: String, name: String) -> StreamingApp {
        StreamingApp(id: UUID().uuidString, name: name, url: URL(string: "android-app://\(package)")!, colorHex: "#5E5CE6", isDefault: false)
    }
}
