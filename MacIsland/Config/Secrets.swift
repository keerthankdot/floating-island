import Foundation

enum SecretsKey {
    static let anthropicAPIKey = "anthropic_api_key"
    static let gmailClientSecret = "gmail_client_secret"
    static let notionToken = "notion_token"
    static let googleClientID = "google_client_id"
}

struct Secrets {
    static var anthropicAPIKey: String? {
        KeychainHelper.retrieve(key: SecretsKey.anthropicAPIKey)
    }

    static var notionToken: String? {
        KeychainHelper.retrieve(key: SecretsKey.notionToken)
    }
}
