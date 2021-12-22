//
//  AppDelegate+Injection.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/09/2021.
//

import SolanaSwift

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        // MARK: - Lifetime app's services
        register { KeychainStorage() }
            .implements(ICloudStorageType.self)
            .implements(NameStorageType.self)
            .implements(SolanaSDKAccountStorage.self)
            .implements(PincodeStorageType.self)
            .implements(AccountStorageType.self)
            .implements(PincodeSeedPhrasesStorage.self)
            .implements((AccountStorageType & NameStorageType).self)
            .implements((AccountStorageType & PincodeStorageType & NameStorageType).self)
            .implements((ICloudStorageType & AccountStorageType & NameStorageType).self)
            .implements((ICloudStorageType & AccountStorageType & NameStorageType & PincodeStorageType).self)
            .scope(.application)
        register {AnalyticsManager()}
            .implements(AnalyticsManagerType.self)
            .scope(.application)
        register {CryptoComparePricesFetcher()}
            .implements(PricesFetcher.self)
            .scope(.application)
        register {NameService()}
            .implements(NameServiceType.self)
            .scope(.application)
        register { AddressFormatter() }
            .implements(AddressFormatterType.self)
            .scope(.application)
        register { LocalizationManager() }
            .implements(LocalizationManagerType.self)
        
        register { UserDefaultsPricesStorage() }
            .implements(PricesStorage.self)
            .scope(.application)
        register { CryptoComparePricesFetcher() }
            .implements(PricesFetcher.self)
            .scope(.application)
        register { NotificationsService() }
            .implements(NotificationsServiceType.self)
            .scope(.application)
        
        register { ClipboardManager() }
            .implements(ClipboardManagerType.self)
            .scope(.application)
        
        // MARK: - Others
        register { SessionBannersAvailabilityState() }
            .scope(.session)
        
        register { PersistentBannersAvailabilityState() }
        register {
            ReserveUsernameBannerAvailabilityRepository(
                sessionBannersAvailabilityState: resolve(SessionBannersAvailabilityState.self),
                persistentBannersAvailabilityState: resolve(PersistentBannersAvailabilityState.self),
                nameStorage: resolve()
            )
        }
            .implements(ReserveUsernameBannerAvailabilityRepositoryType.self)
            .scope(.unique)
        register { BannersManager(usernameBannerRepository: resolve()) }
            .implements(BannersManagerType.self)
            .scope(.unique)
        register { BannerKindTransformer() }
            .implements(BannerKindTransformerType.self)
            .scope(.unique)
        
        register { DAppChannel() }
            .implements(DAppChannelType.self)
        
        // MARK: - Root
        register {Root.ViewModel()}
            .implements(RootViewModelType.self)
            .implements(ChangeNetworkResponder.self)
            .implements(ChangeLanguageResponder.self)
            .implements(CreateOrRestoreWalletHandler.self)
            .implements(OnboardingHandler.self)
            .scope(.shared)
        
        // MARK: - CreateOrRestoreWallet
        register {CreateOrRestoreWallet.ViewModel()}
            .implements(CreateOrRestoreWalletViewModelType.self)
            .scope(.shared)
        
        // CreateWallet
        register {CreateWallet.ViewModel()}
            .implements(CreateWalletViewModelType.self)
            .scope(.shared)
        
        // CreateSecurityKeys
        register {CreateSecurityKeys.ViewModel()}
            .implements(CreateSecurityKeysViewModelType.self)
            .scope(.shared)
        
        // RestoreWallet
        register {RestoreWallet.ViewModel()}
            .implements(RestoreWalletViewModelType.self)
            .implements(AccountRestorationHandler.self)
            .scope(.shared)
        
        // DerivableAccounts
        register { _, args in
            DerivableAccounts.ViewModel(phrases: args())
        }
            .implements(DerivableAccountsListViewModelType.self)
            .scope(.shared)
        
        // MARK: - Onboarding
        register {Onboarding.ViewModel()}
            .implements(OnboardingViewModelType.self)
            .scope(.shared)
        
        // MARK: - Authentication
        register {Authentication.ViewModel()}
            .implements(AuthenticationViewModelType.self)
            .scope(.shared)
        
        // MARK: - ResetPinCodeWithSeedPhrases
        register {ResetPinCodeWithSeedPhrases.ViewModel()}
            .implements(ResetPinCodeWithSeedPhrasesViewModelType.self)
            .scope(.shared)
        
        // MARK: - Main
        register {MainViewModel()}
            .implements(MainViewModelType.self)
            .implements(AuthenticationHandler.self)
            .scope(.shared)

        // MARK: - EnterSeedPhrase
        register { EnterSeed.ViewModel() }
            .implements(EnterSeedViewModelType.self)
            .scope(.unique)
        register { EnterSeedInfo.ViewModel() }
            .implements(EnterSeedInfoViewModelType.self)
            .scope(.unique)
    
        // MARK: - DAppContainer
        register {DAppContainer.ViewModel()}
            .implements(DAppContainerViewModelType.self)
            .scope(.shared)
        
        // MARK: - Moonpay
        register{Moonpay.MoonpayServiceImpl(api: Moonpay.API.fromEnvironment())}
            .implements(MoonpayService.self)
            .scope(.shared)
    
        // MARK: - BuyProvider
        register{BuyProviders.MoonpayFactory()}
            .implements(BuyProviderFactory.self)
            .scope(.application)
        
    }
}

extension ResolverScope {
    static let session = ResolverScopeCache()
}
