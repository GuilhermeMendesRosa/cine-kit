import Foundation
import Testing
@testable import CineKitCore

struct AppDraftTests {
    @Test func trimsName() throws {
        let app = try AppDraft(name: "  Mubi \n", link: "https://mubi.com").validate().get()
        #expect(app.name == "Mubi")
    }

    @Test func rejectsEmptyName() {
        #expect(AppDraft(name: "   ", link: "https://mubi.com").validate() == .failure(.emptyName))
    }

    @Test func rejectsEmptyLink() {
        #expect(AppDraft(name: "Mubi", link: "  ").validate() == .failure(.emptyLink))
    }

    @Test func prefixesHttpsWhenSchemeMissing() throws {
        let app = try AppDraft(name: "Mubi", link: "mubi.com/pt").validate().get()
        #expect(app.url == URL(string: "https://mubi.com/pt"))
    }

    @Test func keepsHttp() throws {
        let app = try AppDraft(name: "Router", link: "http://192.168.0.1").validate().get()
        #expect(app.url == URL(string: "http://192.168.0.1"))
    }

    @Test(arguments: ["ftp://example.com", "javascript:alert(1)"])
    func rejectsUnsupportedScheme(link: String) {
        #expect(AppDraft(name: "X", link: link).validate() == .failure(.unsupportedScheme))
    }

    @Test(arguments: ["https://", "http:///path"])
    func rejectsMissingHost(link: String) {
        #expect(AppDraft(name: "X", link: link).validate() == .failure(.missingHost))
    }
}
