import Testing
@testable import CineKitCore

struct ApkBadgingTests {
    @Test func parsesPackageAndLabel() {
        let output = """
        package: name='com.android.dreams.basic' versionCode='36' versionName='16' platformBuildVersionName='16'
        application-label:'Basic Daydreams'
        application: label='Basic Daydreams' icon=''
        """
        let badging = ApkBadging.parse(output)
        #expect(badging?.package == "com.android.dreams.basic")
        #expect(badging?.label == "Basic Daydreams")
    }

    @Test func fallsBackToPackageWithoutLabel() {
        let badging = ApkBadging.parse("package: name='org.example.tv' versionCode='1'\nsdkVersion:'21'\n")
        #expect(badging?.package == "org.example.tv")
        #expect(badging?.label == "org.example.tv")
    }

    @Test func returnsNilForInvalidOutput() {
        #expect(ApkBadging.parse("ERROR: dump failed because no AndroidManifest.xml found") == nil)
    }
}
