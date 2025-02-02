//
//  WormholeClaimFeeAdapter.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 27.03.2023.
//

import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift
import Wormhole

struct WormholeClaimFee {
    typealias Amount = (crypto: String, fiat: String, isFree: Bool)

    let receive: Amount

    let networkFee: Amount?

    let accountCreationFee: Amount?

    let wormholeBridgeAndTrxFee: Amount?

    let total: Amount?

    static let emptyAmount: Amount = ("", "", false)

    static let empty: Self = .init(
        receive: Self.emptyAmount,
        networkFee: Self.emptyAmount,
        accountCreationFee: nil,
        wormholeBridgeAndTrxFee: Self.emptyAmount,
        total: nil
    )
}

class WormholeClaimFeeAggregator: DataAggregator {
    func transform(input bundle: WormholeBundle?) -> WormholeClaimFee {
        guard let bundle else {
            return .empty
        }

        // Setup formatter
        let cryptoFormatter = CryptoFormatter()
        let currencyFormatter = CurrencyFormatter()

        // Extract amount that user B will receive.
        let receive: WormholeClaimFee.Amount = (
            cryptoFormatter.string(amount: bundle.resultAmount),
            currencyFormatter.string(for: bundle.resultAmount) ?? "",
            false
        )

        let networkFee: WormholeClaimFee.Amount?
        let accountCreationFee: WormholeClaimFee.Amount?
        let wormholeBridgeAndTrxFee: WormholeClaimFee.Amount?
        let total: WormholeClaimFee.Amount?

        // Aggregating data
        if bundle.compensationDeclineReason == nil {
            networkFee = (L10n.paidByKeyApp, L10n.free, true)
            accountCreationFee = (L10n.paidByKeyApp, L10n.free, true)
            wormholeBridgeAndTrxFee = (L10n.paidByKeyApp, L10n.free, true)
            total = (
                cryptoFormatter.string(amount: bundle.resultAmount),
                currencyFormatter.string(amount: bundle.resultAmount),
                false
            )
        } else {
            // Network fee
            if let gasInToken = bundle.fees.gasInToken {
                networkFee = (
                    cryptoFormatter.string(amount: gasInToken),
                    currencyFormatter.string(amount: gasInToken),
                    false
                )
            } else {
                networkFee = nil
            }

            // Create accounts fee
            if let createAccount = bundle.fees.createAccount {
                accountCreationFee = (
                    cryptoFormatter.string(amount: createAccount),
                    currencyFormatter.string(amount: createAccount),
                    false
                )
            } else {
                accountCreationFee = nil
            }

            // Network fee
            if let arbiter = bundle.fees.arbiter {
                wormholeBridgeAndTrxFee = (
                    cryptoFormatter.string(amount: arbiter),
                    currencyFormatter.string(amount: arbiter),
                    false
                )
            } else {
                wormholeBridgeAndTrxFee = nil
            }

            // Total
            let totalInCrypto = [
                bundle.fees.gasInToken?.asCryptoAmount,
                bundle.fees.arbiter?.asCryptoAmount,
                bundle.fees.createAccount?.asCryptoAmount,
            ]
                .compactMap { $0 }
                .reduce(bundle.resultAmount.asCryptoAmount, +)

            let totalInFiat = [
                bundle.fees.gasInToken?.asCurrencyAmount,
                bundle.fees.arbiter?.asCurrencyAmount,
                bundle.fees.createAccount?.asCurrencyAmount,
            ]
                .compactMap { $0 }
                .reduce(bundle.resultAmount.asCurrencyAmount, +)

            total = (
                cryptoFormatter.string(amount: totalInCrypto),
                currencyFormatter.string(amount: totalInFiat),
                false
            )
        }

        return .init(
            receive: receive,
            networkFee: networkFee,
            accountCreationFee: accountCreationFee,
            wormholeBridgeAndTrxFee: wormholeBridgeAndTrxFee,
            total: total
        )
    }
}
