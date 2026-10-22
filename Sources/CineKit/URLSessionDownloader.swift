import CineKitCore
import Foundation

/// Downloads the Android SDK packages (ADR 0018), reporting progress about once per megabyte.
struct URLSessionDownloader: Downloader {
    private final class ProgressDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
        private let progress: @Sendable (Int64) -> Void
        private var observation: NSKeyValueObservation?
        private var reported: Int64 = 0

        init(progress: @escaping @Sendable (Int64) -> Void) {
            self.progress = progress
        }

        func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
            observation = task.observe(\.countOfBytesReceived) { [weak self] task, _ in
                guard let self, task.countOfBytesReceived - reported >= 1 << 20 else { return }
                reported = task.countOfBytesReceived
                progress(reported)
            }
        }
    }

    func download(_ url: URL, progress: @escaping @Sendable (Int64) -> Void) async throws -> URL {
        let (file, response) = try await URLSession.shared.download(from: url, delegate: ProgressDelegate(progress: progress))
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            try? FileManager.default.removeItem(at: file)
            throw URLError(.badServerResponse)
        }
        return file
    }
}
