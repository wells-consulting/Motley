//
// Copyright 2025 Wells Consulting.
//

import Foundation

extension URL: LogTextProviding {

    public func appendingPath(_ name: String) -> URL {
        appendingPathComponent(name)
    }

    public func appendingFile(_ name: String) -> URL {
        appendingPathComponent(name, isDirectory: false)
    }

    public func appendingDir(_ name: String) -> URL {
        appendingPathComponent(name, isDirectory: true)
    }

    public var briefPath: String {
        Array(pathComponents.suffix(2)).joined(separator: "/")
    }

    public var briefContainerFilePath: String {

        guard isFileURL else { return briefPath }

        let fullPath = path
        let prefix = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .deletingLastPathComponent()
            .path

        guard fullPath.hasPrefix(prefix) else { return briefPath }

        let containerID = (prefix as NSString).lastPathComponent
        let relative = fullPath.dropFirst(prefix.count)
        let relativeSuffix = relative.hasPrefix("/") ? relative.dropFirst() : relative

        return "\(containerID)/\(relativeSuffix)"
    }

    public var logText: String {
        redacted()
    }

    public func redacted() -> String {
        guard
            var components = URLComponents(
                url: self,
                resolvingAgainstBaseURL: false
            )
        else {
            return absoluteString
        }

        // Detect common signed URL schemes and nuke the entire query.
        if let items = components.queryItems {
            let names = Set(items.map { $0.name.lowercased() })

            let isAWSPresigned =
                names.contains("x-amz-signature") || names.contains("x-amz-credential")

            let isGoogleSigned =
                names.contains("x-goog-signature") || names.contains("x-goog-credential")

            let isAzureSAS =
                names.contains("sig")
                && (names.contains("se") || names.contains("sp") || names.contains("sr"))

            if isAWSPresigned || isGoogleSigned || isAzureSAS {
                components.percentEncodedQuery = "<redacted-query>"
                return components.string ?? absoluteString
            }
        }

        let exactSensitiveNames: Set<String> = [
            "access_token",
            "refresh_token",
            "id_token",
            "token",
            "auth",
            "authorization",
            "bearer",
            "jwt",

            "api_key",
            "apikey",
            "api-key",
            "key",
            "secret",
            "client_secret",

            "password",
            "passwd",
            "pwd",

            "session",
            "sessionid",
            "session_id",

            "credential",
            "credentials",

            "signature",
            "sig",

            "code",

            "aws_access_key_id",
            "x-amz-signature",
            "x-amz-security-token",
            "x-goog-signature",
            "x-goog-credential",
        ]

        let suspiciousFragments = [
            "token",
            "secret",
            "password",
            "passwd",
            "pwd",
            "auth",
            "credential",
            "signature",
            "sig",
            "apikey",
            "api_key",
        ]

        components.queryItems = components.queryItems?.map { item in

            let key = item.name.lowercased()

            guard let value = item.value else {
                return item
            }

            let shouldRedact =
                exactSensitiveNames.contains(key)
                || suspiciousFragments.contains(where: key.contains)
                || looksLikeJWT(value) || value.count > 64

            if shouldRedact {
                return URLQueryItem(name: item.name, value: "<redacted>")
            }

            return item
        }

        return components.string ?? absoluteString
    }

    private func looksLikeJWT(_ value: String) -> Bool {
        let parts = value.split(separator: ".")

        guard parts.count == 3 else {
            return false
        }

        return parts.allSatisfy { part in
            part.count >= 8
                && part.allSatisfy {
                    $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_"
                }
        }
    }
}
