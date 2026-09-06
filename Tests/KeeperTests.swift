//
// Motley – Michael's Swift Toolkit
// Copyright 2025-2026 Wells Consulting.
//

import Foundation
@testable import Motley
import Testing

// MARK: - KeeperError

@Suite("KeeperError")
struct KeeperErrorTests {

    @Test("itemNotFound has correct summary")
    func itemNotFound() {
        let error = KeeperError.itemNotFound(key: "myKey")
        #expect(error.summary == "Item not found.")
        #expect(error.details?.contains("myKey") == true)
        #expect(error.status == errSecItemNotFound)
    }

    @Test("saveFailed includes key and OSStatus in details")
    func saveFailed() {
        let error = KeeperError.saveFailed(key: "token", status: -25299)
        #expect(error.details?.contains("token") == true)
        #expect(error.details?.contains("-25299") == true)
        #expect(error.status == -25299)
    }

    @Test("loadFailed includes key and OSStatus in details")
    func loadFailed() {
        let error = KeeperError.loadFailed(key: "secret", status: -25300)
        #expect(error.details?.contains("secret") == true)
        #expect(error.details?.contains("-25300") == true)
        #expect(error.status == -25300)
    }

    @Test("deleteFailed includes key and OSStatus in details")
    func deleteFailed() {
        let error = KeeperError.deleteFailed(key: "old", status: -25244)
        #expect(error.details?.contains("old") == true)
        #expect(error.details?.contains("-25244") == true)
        #expect(error.status == -25244)
    }

    @Test("encodingFailed wraps underlying error")
    func encodingFailed() {
        struct TestError: Error {}
        let error = KeeperError.encodingFailed(key: "data", underlyingError: TestError())
        #expect(error.underlyingError is TestError)
        #expect(error.details?.contains("data") == true)
    }

    @Test("decodingFailed wraps underlying error")
    func decodingFailed() {
        struct TestError: Error {}
        let error = KeeperError.decodingFailed(key: "data", underlyingError: TestError())
        #expect(error.underlyingError is TestError)
        #expect(error.details?.contains("data") == true)
    }
}

// MARK: - SelfSignedCertificateDelegate

@Suite("SelfSignedCertificateDelegate")
struct SelfSignedCertificateDelegateTests {

    @Test("Conforms to URLSessionDelegate and URLSessionTaskDelegate")
    func conformance() {
        // Protocol conformance is verified at compile time by the typed bindings.
        let _: any URLSessionDelegate = SelfSignedCertificateDelegate()
        let _: any URLSessionTaskDelegate = SelfSignedCertificateDelegate()
    }
}
