import Foundation

// MARK: - Message

public struct SwapAlertLoggerMessage: Codable {
    public let tokenA: SwapAlertLoggerMessageTokenA
    public let tokenB: SwapAlertLoggerMessageTokenB
    public let route, userPubkey, slippage, feeRelayerTransaction: String
    public let platform, appVersion, timestamp, blockchainError: String
    
    enum CodingKeys: String, CodingKey {
        case tokenA = "token_a"
        case tokenB = "token_b"
        case route
        case userPubkey = "user_pubkey"
        case slippage
        case feeRelayerTransaction = "fee_relayer_transaction"
        case platform
        case appVersion = "app_version"
        case timestamp
        case blockchainError = "blockchain_error"
    }
    
    public init(tokenA: SwapAlertLoggerMessageTokenA, tokenB: SwapAlertLoggerMessageTokenB, route: String, userPubkey: String, slippage: String, feeRelayerTransaction: String, platform: String, appVersion: String, timestamp: String, blockchainError: String) {
        self.tokenA = tokenA
        self.tokenB = tokenB
        self.route = route
        self.userPubkey = userPubkey
        self.slippage = slippage
        self.feeRelayerTransaction = feeRelayerTransaction
        self.platform = platform
        self.appVersion = appVersion
        self.timestamp = timestamp
        self.blockchainError = blockchainError
    }
}

// MARK: - TokenA
public struct SwapAlertLoggerMessageTokenA: Codable {
    public let name, mint, sendAmount: String
    
    enum CodingKeys: String, CodingKey {
        case name, mint
        case sendAmount = "send_amount"
    }
    
    public init(name: String, mint: String, sendAmount: String) {
        self.name = name
        self.mint = mint
        self.sendAmount = sendAmount
    }
}

// MARK: - TokenB
public struct SwapAlertLoggerMessageTokenB: Codable {
    public let name, mint, expectedAmount: String
    
    enum CodingKeys: String, CodingKey {
        case name, mint
        case expectedAmount = "expected_amount"
    }
    
    public init(name: String, mint: String, expectedAmount: String) {
        self.name = name
        self.mint = mint
        self.expectedAmount = expectedAmount
    }
}
