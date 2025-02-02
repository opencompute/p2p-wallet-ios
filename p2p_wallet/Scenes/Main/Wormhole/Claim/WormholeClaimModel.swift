import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Wormhole

protocol WormholeClaimModel {
    var icon: URL? { get }

    var title: String { get }

    var subtitle: String { get }

    var claimButtonTitle: String { get }

    var claimButtonEnable: Bool { get }
    
    var isOpenFeesVisible: Bool { get }

    var shouldShowBanner: Bool { get }

    var fees: String { get }

    var getAmount: String? { get }

    var feesButtonEnable: Bool { get }
    
    var isLoading: Bool { get }
}

struct WormholeClaimMockModel: WormholeClaimModel {
    var icon: URL?

    var title: String

    var subtitle: String

    var claimButtonTitle: String

    var claimButtonEnable: Bool

    var isOpenFeesVisible: Bool

    var shouldShowBanner: Bool

    var fees: String

    var getAmount: String?

    var feesButtonEnable: Bool
    
    var isLoading: Bool
}

struct WormholeClaimEthereumModel: WormholeClaimModel {
    let account: EthereumAccount
    let bundle: AsyncValueState<WormholeBundle?>

    var icon: URL? {
        account.token.logo
    }

    var title: String {
        let token = account.representedBalance.token
        return CryptoFormatterFactory.formatter(with: token, style: .short)
            .string(for: account.representedBalance)
            ?? "0 \(account.token.symbol)"
    }

    var subtitle: String {
        guard let currencyAmount = account.balanceInFiat else {
            return ""
        }

        let formattedValue = CurrencyFormatter().string(amount: currencyAmount)
        return "≈ \(formattedValue)"
    }

    var claimButtonTitle: String {
        guard !isNotEnoughAmount else {
            return L10n.addFunds
        }

        if bundle.value?.resultAmount != nil {
            return L10n.claim
        } else {
            if bundle.error != nil {
                return L10n.claim
            } else {
                return L10n.loading
            }
        }
    }

    var claimButtonEnable: Bool {
        if isNotEnoughAmount {
            return true
        }
        switch bundle.status {
        case .fetching, .initializing:
            return false
        case .ready:
            return true
        }
    }

    var isOpenFeesVisible: Bool {
        !bundle.hasError
    }

    var shouldShowBanner: Bool {
        bundle.hasError ? isNotEnoughAmount : !isLoading
    }

    var fees: String {
        let bundle = bundle.value

        guard let bundle else {
            if isNotEnoughAmount {
                  return L10n.moreThanTheReceivedAmount
            }
            return L10n.isUnavailable(L10n.value)
        }

        if bundle.compensationDeclineReason == nil {
            return L10n.paidByKeyApp
        }

        return "~ " + CurrencyFormatter().string(amount: bundle.fees.totalInFiat)
    }

    var getAmount: String? {
        guard let resultAmount = bundle.value?.resultAmount else {
            return nil
        }

        let cryptoFormatter = CryptoFormatter()
        let currencyFormatter = CurrencyFormatter()
        
        let formattedCryptoAmount = cryptoFormatter.string(amount: resultAmount)
        let formattedCurrencyAmount = currencyFormatter.string(amount: resultAmount)
        
        return "\(formattedCryptoAmount) (≈ \(formattedCurrencyAmount))"
        
    }

    var feesButtonEnable: Bool {
        bundle.value?.fees != nil
    }
    
    var isLoading: Bool {
        bundle.isFetching
    }

    private var isNotEnoughAmount: Bool {
        if let error = bundle.error as? JSONRPCError<String>, error.code == -32007 {
            return true
        }
        return false
    }
}
