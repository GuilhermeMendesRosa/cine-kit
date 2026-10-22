/// Reads the foreground package from `dumpsys activity activities`.
public enum ForegroundActivity {
    /// Matches `topResumedActivity=` and `(m)ResumedActivity:` lines: `ActivityRecord{<id> u0 <package>/<activity> t5}`.
    public static func package(fromDumpsys output: String) -> String? {
        output.firstMatch(of: /(?:topResumedActivity=|ResumedActivity:\s*)ActivityRecord\{\S+ \S+ ([^\/\s]+)\//).map { String($0.1) }
    }
}
