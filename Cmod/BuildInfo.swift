extension BuildInfo {
    nonisolated static var displayVersion: String {
        "\(version) (\(gitCommitHash))"
    }
}
