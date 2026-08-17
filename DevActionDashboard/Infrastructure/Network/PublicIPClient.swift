import Foundation

/// Resolves the public IP address via HTTPS (ipify).
struct PublicIPClient: Sendable {
    private let session: URLSession
    private let endpoint: URL

    init(session: URLSession = .shared, endpoint: URL = URL(string: "https://api.ipify.org")!) {
        self.session = session
        self.endpoint = endpoint
    }

    func fetchPublicIP() async throws -> String {
        let (data, response) = try await session.data(from: endpoint)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NetworkError.publicIPUnavailable
        }

        let ip = String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard IPAddressText.isValid(ip) else {
            throw NetworkError.publicIPUnavailable
        }
        return ip
    }
}
