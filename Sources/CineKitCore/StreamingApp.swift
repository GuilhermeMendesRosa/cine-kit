import Foundation

public struct StreamingApp: Codable, Identifiable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var url: URL
    public var colorHex: String
    public var imageFileName: String?
    public var isDefault: Bool

    public init(id: String, name: String, url: URL, colorHex: String, imageFileName: String? = nil, isDefault: Bool) {
        self.id = id
        self.name = name
        self.url = url
        self.colorHex = colorHex
        self.imageFileName = imageFileName
        self.isDefault = isDefault
    }
}
