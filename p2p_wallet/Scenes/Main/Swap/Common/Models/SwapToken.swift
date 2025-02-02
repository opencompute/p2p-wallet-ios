import SolanaSwift
import Jupiter

struct SwapToken: Equatable {
    let token: Token
    let userWallet: Wallet?

    var address: String { token.address }
}

extension SwapToken {
    static let nativeSolana = SwapToken(
        token: .nativeSolana,
        userWallet: nil)
}

extension SwapToken {
    static var popularTokenMints: [String] {
        [
            "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", // USDC
            "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB", // USDT
            "So11111111111111111111111111111111111111112",  // SOL
            "3NZ9JMVBmGAqocybic2c7LQCJScmgsAZ6vQqTDzcqmJh", // BTC
            "7vfCXTUXx5WJV5JADk17DUJ4ksgau7utNKj4b963voxs"  // ETH
        ]
    }

    var isPopular: Bool {
        Self.popularTokenMints.contains(token.address)
    }
}
