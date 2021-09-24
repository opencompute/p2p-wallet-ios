//
//  AppDelegate+Injection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/09/2021.
//

import Foundation
import SolanaSwift

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        register {KeychainAccountStorage()}
            .implements(SolanaSDKAccountStorage.self)
            .scope(.application)
        register {AnalyticsManager()}
            .implements(AnalyticsManagerType.self)
            .scope(.application)
        
        // MARK: - Root
        register {Root.ViewModel()}
            .implements(RootViewModelType.self)
            .implements(ChangeNetworkResponder.self)
            .implements(ChangeLanguageResponder.self)
            .implements(CreateOrRestoreWalletHandler.self)
            .implements(OnboardingHandler.self)
        
        // MARK: - CreateOrRestoreWallet
        register {CreateOrRestoreWallet.ViewModel()}
            .implements(CreateOrRestoreWalletViewModelType.self)
        
        // CreateWallet
        register {CreateWallet.ViewModel()}
            .implements(CreateWalletViewModelType.self)
        
        // CreateSecurityKeys
        register {CreateSecurityKeys.ViewModel()}
            .implements(CreateSecurityKeysViewModelType.self)
        
        // RestoreWallet
        register {RestoreWallet.ViewModel()}
            .implements(RestoreWalletViewModelType.self)
            .implements(AccountRestorationHandler.self)
        
        // MARK: - Onboarding
        register {Onboarding.ViewModel()}
            .implements(OnboardingViewModelType.self)
        
        // MARK: - ResetPinCodeWithSeedPhrases
        register {ResetPinCodeWithSeedPhrases.ViewModel()}
            .implements(ResetPinCodeWithSeedPhrasesViewModelType.self)
    }
}
