public enum WebBackAction: Equatable, Sendable {
    case exitFullscreen, sendBackspace, goBack, exit
}

/// What Back (a released Esc) does in a web service (ADR 0012).
public enum WebBack {
    public static func action(isFullscreen: Bool, handlesBack: Bool, canGoBack: Bool) -> WebBackAction {
        if isFullscreen { return .exitFullscreen }
        if handlesBack { return .sendBackspace }
        return canGoBack ? .goBack : .exit
    }
}
