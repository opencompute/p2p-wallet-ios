import Jupiter
import FeeRelayerSwift
import SolanaSwift

struct JupiterSwapState: Equatable {
    // MARK: - Nested type
    
    enum ErrorReason: Equatable {
        case initializationFailed
        case networkConnectionError

        case notEnoughFromToken
        case inputTooHigh(Double)
        case equalSwapTokens

        case unknown
        case coingeckoPriceFailure
        case routeIsNotFound
    }

    enum Status: Equatable {
        case requiredInitialize
        case initializing
        case loadingAmountTo
        case loadingTokenTo
        case quoteLoading
        case switching
        case ready
        case error(reason: ErrorReason)
    }

    enum SwapPriceImpact {
        case medium
        case high
    }

    // MARK: - Properties

    /// Status of current state
    var status: Status

    /// Available routes for every token mint
    var routeMap: RouteMap
    
    /// Current token prices map
    var tokenPriceMap: TokenPriceMap
    
    /// Pre-selected route
    var route: Route?
    
    /// All available routes for current tokens pair
    var routes: [Route]
    
    /// Info of all swappable tokens
    var swapTokens: [SwapToken]
    
    /// Price info between from token and to token
    var priceInfo: SwapPriceInfo

    /// Token that user's swapping from
    var fromToken: SwapToken

    /// Token that user's swapping to
    var toToken: SwapToken
    
    /// SlippageBps is slippage multiplied by 100 (be careful)
    var slippageBps: Int
    
    /// FeeRelayer's relay context
    var relayContext: RelayContext?
    
    // MARK: - Computed properties
    
    var amountFrom: Double {
        guard let route, let amountFrom = UInt64(route.inAmount) else { return 0 }
        return amountFrom.convertToBalance(decimals: fromToken.token.decimals)
    }
    
    var amountFromFiat: Double {
        priceInfo.fromPrice * amountFrom
    }
    
    var amountTo: Double {
        guard let route, let amountTo = UInt64(route.outAmount) else { return 0 }
        return amountTo.convertToBalance(decimals: toToken.token.decimals)
    }
    
    var amountToFiat: Double {
        priceInfo.toPrice * amountTo
    }
    
    var priceImpact: SwapPriceImpact? {
        switch route?.priceImpactPct {
        case let val where val >= 0.01 && val < 0.03:
            return .medium
        case let val where val >= 0.03:
            return .high
        default:
            return nil
        }
    }

    var bestOutAmount: UInt64 {
        routes.map(\.outAmount).compactMap(UInt64.init).max() ?? 0
    }
    
    var minimumReceivedAmount: Double? {
        guard let outAmountString = route?.outAmount,
              let outAmount = UInt64(outAmountString)
        else {
            return nil
        }
        let slippage = Double(slippageBps) / 100
        return outAmount.convertToBalance(decimals: toToken.token.decimals) * (1 - slippage)
    }
    
    var possibleToTokens: [SwapToken] {
        let toAddresses = Set(routeMap.indexesRouteMap[fromToken.address] ?? [])
        return swapTokens.filter { toAddresses.contains($0.token.address) }
    }
    
    /// Network fee of the transaction, can be modified by the fee relayer service
    var networkFee: SwapFeeInfo? {
        guard let route else { return nil }
        
        // FIXME: - network fee with fee relayer, Temporarily paying with SOL
        let networkFeeAmount = relayContext.lamportsPerSignature // user's signature only
            .convertToBalance(decimals: Token.nativeSolana.decimals)
        return SwapFeeInfo(
            amount: networkFeeAmount,
            tokenSymbol: "SOL",
            tokenName: "Solana",
            amountInFiat: tokenPriceMap[Token.nativeSolana.address].value * networkFeeAmount,
            pct: nil,
            canBePaidByKeyApp: true
        )
    }
    
    var accountCreationFee: SwapFeeInfo? {
        guard let route else { return nil }
        let nonCreatedTokenMints = route.marketInfos.map(\.outputMint)
            .compactMap { mint in
                swapTokens.first(where: { $0.token.address == mint && $0.userWallet == nil })?.address
            }
        
        let accountCreationFeeAmount = (relayContext.minimumTokenAccountBalance * UInt64(nonCreatedTokenMints.count))
            .convertToBalance(decimals: Token.nativeSolana.decimals)
        let accountCreationFee = SwapFeeInfo(
            amount: accountCreationFeeAmount,
            tokenSymbol: "SOL",
            tokenName: "Solana",
            amountInFiat: tokenPriceMap[Token.nativeSolana.address].value * accountCreationFeeAmount,
            pct: nil,
            canBePaidByKeyApp: false
        )
    }
    
    var liquidityFee: [SwapFeeInfo] {
        guard let route else { return [] }
        return route.marketInfos.map(\.lpFee)
            .compactMap { lqFee -> SwapFeeInfo? in
                guard let token = state.swapTokens.map(\.token).first(where: { $0.address == lqFee.mint }),
                      let amount = UInt64(lqFee.amount)?.convertToBalance(decimals: token.decimals)
                else {
                    return nil
                }
                
                let price = priceService.getCurrentPrice(for: token.address)
                
                return SwapFeeInfo(
                    amount: amount,
                    tokenSymbol: token.symbol,
                    tokenName: token.name,
                    amountInFiat: price * amount,
                    pct: lqFee.pct,
                    canBePaidByKeyApp: false
                )
            }
    }
    
    // MARK: - Initializing state

    static var zero: Self {
        Self.init(
            status: .requiredInitialize,
            routeMap: RouteMap(mintKeys: [], indexesRouteMap: [:]),
            tokenPriceMap: [:],
            route: nil,
            routes: [],
            swapTokens: [],
            priceInfo: SwapPriceInfo(fromPrice: .zero, toPrice: .zero),
            fromToken: .nativeSolana,
            toToken: .nativeSolana,
            slippageBps: 0,
            relayContext: nil
        )
    }
    
    // MARK: - Modified function
    
    func error(_ reason: ErrorReason) -> Self {
        var state = self
        state.status = .error(reason: reason)
        return state
    }

    func modified(_ modify: (inout Self) -> Void) -> Self {
        var state = self
        modify(&state)
        return state
    }
}
