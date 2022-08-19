// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding
import Resolver
import SolanaSwift

struct RestoreOption: OptionSet {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let keychain = RestoreOption(rawValue: 1 << 0)
    static let seed = RestoreOption(rawValue: 1 << 1)
    static let custom = RestoreOption(rawValue: 1 << 2)
    static let socialApple = RestoreOption(rawValue: 1 << 3)
    static let socialGoogle = RestoreOption(rawValue: 1 << 4)
}

final class RestoreWalletViewModel: BaseViewModel {
    let deviceShare: String?
    let availableRestoreOptions: RestoreOption
    let stateMachine: RestoreWalletStateMachine

    @Injected var authService: AuthService

    init(tKeyFacade: TKeyFacade? = nil) {
        deviceShare = Resolver.resolve(AccountStorageType.self).deviceShare

        stateMachine = .init(provider: RestoreWalletFlowContainer(
            tKeyFacade: tKeyFacade ?? TKeyMockupFacade(),
            deviceShare: deviceShare,
            authService: AuthServiceBridge(),
            apiGatewayClient: APIGatewayClientImplMock(),
            securityStatusProvider: Resolver.resolve(),
            icloudAccountProvider: Resolver.resolve(KeychainStorage.self)
        ))

        var options: RestoreOption = [.seed, .custom]
        if deviceShare != nil {
            options.insert(RestoreOption.socialApple)
            options.insert(RestoreOption.socialGoogle)
        }
        if true {
            options.insert(RestoreOption.keychain)
        }

        availableRestoreOptions = options
    }
}

extension KeychainStorage: ICloudAccountProvider {
    func getAll() async throws -> [(name: String?, phrase: String, derivablePath: DerivablePath)] {
        guard let accounts = accountFromICloud() else { return [] }
        return accounts.map { (name: $0.name, phrase: $0.phrase, derivablePath: $0.derivablePath) }
    }
}
