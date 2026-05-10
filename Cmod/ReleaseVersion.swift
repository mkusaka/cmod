enum ReleaseVersion {
    nonisolated static func buildVersion(for marketingVersion: String) -> Int? {
        let components = marketingVersion.split(separator: ".", omittingEmptySubsequences: false)
        guard (1 ... 3).contains(components.count) else {
            return nil
        }

        let values = components.map { Int($0) }
        guard values.allSatisfy({ $0 != nil }) else {
            return nil
        }

        let major = values[0] ?? 0
        let minor = values.count > 1 ? values[1] ?? 0 : 0
        let patch = values.count > 2 ? values[2] ?? 0 : 0

        return major * 10000 + minor * 100 + patch
    }
}
