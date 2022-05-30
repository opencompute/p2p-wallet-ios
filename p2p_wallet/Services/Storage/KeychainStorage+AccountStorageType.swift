// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

extension KeychainStorage: AccountStorageType {
    func save(phrases: [String]) throws {
        keychain.set(phrases.joined(separator: " "), forKey: phrasesKey)
        _account = nil
    }

    func save(walletIndex: Int) throws {
        keychain.set("\(walletIndex)", forKey: walletIndexKey)
        _account = nil
    }

    func getDerivablePath() -> DerivablePath? {
        guard
            let derivableTypeRaw = keychain.get(derivableTypeKey),
            let derivableType = DerivablePath.DerivableType(rawValue: derivableTypeRaw)
        else { return nil }

        let walletIndexRaw = keychain.get(walletIndexKey)
        let walletIndex = Int(walletIndexRaw ?? "0")

        return .init(type: derivableType, walletIndex: walletIndex ?? 0)
    }

    func save(derivableType _: DerivablePath.DerivableType) throws { fatalError("Method has not been implemented") }

    public var account: SolanaSwift.Account? {
        if let account = _account { return account }

        guard let phrases = keychain.get(phrasesKey)?.components(separatedBy: " ") else { return nil }
        let derivableTypeRaw = keychain.get(derivableTypeKey) ?? ""
        let walletIndexRaw = keychain.get(walletIndexKey) ?? ""

        let defaultDerivablePath = DerivablePath.default

        let derivableType = DerivablePath.DerivableType(rawValue: derivableTypeRaw) ?? defaultDerivablePath.type
        let walletIndex = Int(walletIndexRaw) ?? defaultDerivablePath.walletIndex

        return try? SolanaSwift.Account(
            phrase: phrases,
            network: Defaults.apiEndPoint.network,
            derivablePath: .init(type: derivableType, walletIndex: walletIndex)
        )
    }

    public func save(_: SolanaSwift.Account) throws { fatalError("Method has not been implemented") }

    func clearAccount() {
        removeCurrentAccount()
    }
}
