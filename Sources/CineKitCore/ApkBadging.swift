/// Reads the output of `aapt2 dump badging <apk>`.
public enum ApkBadging {
    public static func parse(_ output: String) -> (package: String, label: String)? {
        guard let package = output.firstMatch(of: /(?m)^package: name='([^']+)'/)?.1 else { return nil }
        let label = output.firstMatch(of: /(?m)^application-label:'([^']*)'/)?.1
        return (String(package), String(label ?? package))
    }
}
