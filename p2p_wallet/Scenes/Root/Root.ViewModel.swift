//
//  Root.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 08/06/2021.
//

import Foundation
import RxSwift
import RxCocoa
import Resolver

protocol RootViewModelType {
    var navigationSceneDriver: Driver<Root.NavigatableScene?> {get}
    var isLoadingDriver: Driver<Bool> {get}
    
    func reload()
    func logout()
    func finishSetup()
}

protocol CreateOrRestoreWalletHandler {
    func creatingWalletDidComplete(phrases: [String]?, derivablePath: SolanaSDK.DerivablePath?, name: String?)
    func restoringWalletDidComplete(phrases: [String]?, derivablePath: SolanaSDK.DerivablePath?, name: String?)
    func creatingOrRestoringWalletDidCancel()
}

extension Root {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var accountStorage: KeychainAccountStorage
        @Injected private var analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private var isRestoration = false
        private var showAuthenticationOnMainOnAppear = true
        private var resolvedName: String?
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let isLoadingSubject = BehaviorRelay<Bool>(value: false)
        
        // MARK: - Actions
        func reload() {
            isLoadingSubject.accept(true)
            
            DispatchQueue.global(qos: .userInteractive).async {
                let account = self.accountStorage.account
                DispatchQueue.main.async {
                    if account == nil {
                        self.showAuthenticationOnMainOnAppear = false
                        self.navigationSubject.accept(.createOrRestoreWallet)
                    } else if self.accountStorage.pinCode == nil ||
                                !Defaults.didSetEnableBiometry ||
                                !Defaults.didSetEnableNotifications
                    {
                        self.showAuthenticationOnMainOnAppear = false
                        self.navigationSubject.accept(.onboarding)
                    } else {
                        self.navigationSubject.accept(.main(showAuthenticationWhenAppears: self.showAuthenticationOnMainOnAppear))
                    }
                }
            }
        }
        
        func logout() {
            ResolverScope.session.reset()
            accountStorage.clear()
            Defaults.walletName = [:]
            Defaults.didSetEnableBiometry = false
            Defaults.didSetEnableNotifications = false
            Defaults.didBackupOffline = false
            Defaults.renVMSession = nil
            Defaults.renVMProcessingTxs = []
            Defaults.forceCloseNameServiceBanner = false
            reload()
        }
        
        @objc func finishSetup() {
            analyticsManager.log(event: .setupFinishClick)
            reload()
        }
    }
}

extension Root.ViewModel: RootViewModelType {
    var navigationSceneDriver: Driver<Root.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var isLoadingDriver: Driver<Bool> {
        isLoadingSubject.asDriver()
    }
}

extension Root.ViewModel: ChangeNetworkResponder {
    func changeAPIEndpoint(to endpoint: SolanaSDK.APIEndPoint) {
        Defaults.apiEndPoint = endpoint
        
        showAuthenticationOnMainOnAppear = false
        reload()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIApplication.shared.showToast(message: "✅ " + L10n.networkChanged)
        }
    }
}

extension Root.ViewModel: ChangeLanguageResponder {
    func languageDidChange(to language: LocalizedLanguage) {
        UIApplication.languageChanged()
        analyticsManager.log(event: .settingsLanguageSelected(language: language.code))
        
        showAuthenticationOnMainOnAppear = false
        reload()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let languageChangedText = language.originalName.map(L10n.changedLanguageTo) ?? L10n.interfaceLanguageChanged

            UIApplication.shared.showToast(message: "✅ " + languageChangedText)
        }
    }
}

extension Root.ViewModel: CreateOrRestoreWalletHandler {
    func creatingWalletDidComplete(phrases: [String]?, derivablePath: SolanaSDK.DerivablePath?, name: String?) {
        isRestoration = false
        resolvedName = name
        navigationSubject.accept(.onboarding)
        analyticsManager.log(event: .setupOpen(fromPage: "create_wallet"))
        saveAccountToStorage(phrases: phrases, derivablePath: derivablePath, name: name)
    }
    
    func restoringWalletDidComplete(phrases: [String]?, derivablePath: SolanaSDK.DerivablePath?, name: String?) {
        isRestoration = true
        resolvedName = name
        navigationSubject.accept(.onboarding)
        analyticsManager.log(event: .setupOpen(fromPage: "recovery"))
        saveAccountToStorage(phrases: phrases, derivablePath: derivablePath, name: name)
    }
    
    func creatingOrRestoringWalletDidCancel() {
        logout()
    }
    
    private func saveAccountToStorage(phrases: [String]?, derivablePath: SolanaSDK.DerivablePath?, name: String?) {
        guard let phrases = phrases, let derivablePath = derivablePath else {
            creatingOrRestoringWalletDidCancel()
            return
        }
        
        isLoadingSubject.accept(true)
        DispatchQueue.global().async { [weak self] in
            do {
                try self?.accountStorage.save(phrases: phrases)
                try self?.accountStorage.save(derivableType: derivablePath.type)
                try self?.accountStorage.save(walletIndex: derivablePath.walletIndex)
                
                if let name = name {
                    self?.accountStorage.save(name: name)
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.isLoadingSubject.accept(false)
                }
            } catch {
                self?.isLoadingSubject.accept(false)
                DispatchQueue.main.async {
                    UIApplication.shared.showToast(message: (error as? SolanaSDK.Error)?.errorDescription ?? error.localizedDescription)
                    self?.creatingOrRestoringWalletDidCancel()
                }
            }
        }
    }
}

extension Root.ViewModel: OnboardingHandler {
    func onboardingDidCancel() {
        logout()
    }
    
    @objc func onboardingDidComplete() {
        let event: AnalyticsEvent = isRestoration ? .setupWelcomeBackOpen: .setupFinishOpen
        analyticsManager.log(event: event)
        navigationSubject.accept(.onboardingDone(isRestoration: isRestoration, name: resolvedName))
    }
}
