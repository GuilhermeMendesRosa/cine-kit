import Testing
@testable import CineKitCore

struct ForegroundActivityTests {
    @Test func parsesTopResumedActivity() {
        let dumpsys = """
        ACTIVITY MANAGER ACTIVITIES (dumpsys activity activities)
              topResumedActivity=ActivityRecord{137678013 u0 com.google.android.tvlauncher/.MainActivity t5}
          ResumedActivity: ActivityRecord{137678013 u0 com.google.android.tvlauncher/.MainActivity t5}
        """
        #expect(ForegroundActivity.package(fromDumpsys: dumpsys) == "com.google.android.tvlauncher")
    }

    @Test func parsesLegacyResumedActivity() {
        let dumpsys = "    mResumedActivity: ActivityRecord{a1b2c3 u0 org.jellyfin.androidtv/.ui.startup.StartupActivity t12}\n"
        #expect(ForegroundActivity.package(fromDumpsys: dumpsys) == "org.jellyfin.androidtv")
    }

    @Test func returnsNilWithoutResumedActivity() {
        #expect(ForegroundActivity.package(fromDumpsys: "ACTIVITY MANAGER ACTIVITIES\n  (nothing)\n") == nil)
    }
}
