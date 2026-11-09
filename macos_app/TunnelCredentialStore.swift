import Foundation
import Security

struct TunnelCredentialStore {
    private let service: String
    private let account: String
    private let label: String

    init(service: String = "app.easycolab.studio.cloudflare-tunnel", account: String = "tunnel-token", label: String = "EasyColab Cloudflare Tunnel Token") {
        self.service = service
        self.account = account
        self.label = label
    }

    static let huggingFace = TunnelCredentialStore(service: "app.easycolab.studio.huggingface", account: "hf-token", label: "EasyColab Hugging Face Token")

    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: false
        ]
    }

    func load() throws -> String {
        var lookup = query
        lookup[kSecReturnData as String] = true
        lookup[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(lookup as CFDictionary, &result)
        if status == errSecItemNotFound { return "" }
        guard status == errSecSuccess else { throw storeError(status) }
        guard let data = result as? Data, let token = String(data: data, encoding: .utf8) else {
            throw storeError(errSecDecode)
        }
        return token
    }

    func save(_ token: String) throws {
        guard !token.isEmpty, !token.contains(where: { $0.isWhitespace }), !token.contains("\0"), token.utf8.count <= 2560 else {
            throw storeError(errSecParam)
        }
        let attributes: [String: Any] = [kSecValueData as String: Data(token.utf8)]
        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item.merge(attributes) { _, updated in updated }
            item[kSecAttrLabel as String] = label
            status = SecItemAdd(item as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw storeError(status) }
    }

    func delete() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw storeError(status) }
    }

    private func storeError(_ status: OSStatus) -> NSError {
        NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [
            NSLocalizedDescriptionKey: "Keychain error (\(status))"
        ])
    }
}
