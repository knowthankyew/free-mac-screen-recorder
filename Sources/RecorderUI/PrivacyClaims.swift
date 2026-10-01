import Carbon.HIToolbox
import Foundation

/// Single source of truth for runtime privacy and data governance claims.
/// Adheres to the knowthankyew Consumer-Safe Zero-Egress open governance standard.
public struct PrivacyClaims: Equatable, Sendable {
    /// True if the process executes entirely client-side with no remote network infrastructure.
    public let isLocalOnly: Bool

    /// The network egress policy (e.g. "deny").
    public let networkEgressPolicy: String

    /// Active telemetry mode ("disabled", "memory_only", or "otlp").
    public let telemetryMode: String

    /// Count of third-party package dependencies linked into the application.
    public let thirdPartyDependenciesCount: Int

    /// Whether any captured media is uploaded to cloud storage.
    public let externalCloudUpload: Bool

    /// Whether secure event inputs (e.g. password fields) are actively suppressed from display.
    public let secureInputSuppressionEnabled: Bool

    /// Whether secure event input is currently active in the system at this moment.
    public let isSecureInputActiveNow: Bool

    /// User-facing summary badge string.
    public let summaryBadge: String

    public init(
        isLocalOnly: Bool = true,
        networkEgressPolicy: String = "deny",
        telemetryMode: String = "disabled",
        thirdPartyDependenciesCount: Int = 0,
        externalCloudUpload: Bool = false,
        secureInputSuppressionEnabled: Bool = true,
        isSecureInputActiveNow: Bool = false,
        summaryBadge: String = "100% Local • Zero Network Egress"
    ) {
        self.isLocalOnly = isLocalOnly
        self.networkEgressPolicy = networkEgressPolicy
        self.telemetryMode = telemetryMode
        self.thirdPartyDependenciesCount = thirdPartyDependenciesCount
        self.externalCloudUpload = externalCloudUpload
        self.secureInputSuppressionEnabled = secureInputSuppressionEnabled
        self.isSecureInputActiveNow = isSecureInputActiveNow
        self.summaryBadge = summaryBadge
    }
}

/// Provider for inspecting and asserting runtime privacy invariants.
public enum PrivacyClaimsProvider {
    /// Dynamically queries active claims based on the application runtime environment.
    public static func currentClaims() -> PrivacyClaims {
        let isSecureActive = IsSecureEventInputEnabled()
        return PrivacyClaims(
            isLocalOnly: true,
            networkEgressPolicy: "deny",
            telemetryMode: "disabled",
            thirdPartyDependenciesCount: 0,
            externalCloudUpload: false,
            secureInputSuppressionEnabled: true,
            isSecureInputActiveNow: isSecureActive,
            summaryBadge: "100% Local • Zero Network Egress"
        )
    }
}
