import Foundation

public enum DefaultApps {
    public static let all: [StreamingApp] = [
        app("netflix", "Netflix", "https://www.netflix.com", "#E50914"),
        app("prime-video", "Prime Video", "https://www.primevideo.com", "#00A8E1"),
        app("disney-plus", "Disney+", "https://www.disneyplus.com", "#113CCF"),
        app("hbo-max", "HBO Max", "https://play.hbomax.com", "#002BE7"),
        app("globoplay", "Globoplay", "https://globoplay.globo.com", "#FB0234"),
        app("youtube", "YouTube", "https://www.youtube.com", "#FF0000"),
    ]

    private static func app(_ id: String, _ name: String, _ url: String, _ colorHex: String) -> StreamingApp {
        StreamingApp(id: id, name: name, url: URL(string: url)!, colorHex: colorHex, isDefault: true)
    }
}
