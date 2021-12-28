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
import LocalAuthentication

protocol RootViewModelType {
    var navigationSceneDriver: Driver<Root.NavigatableScene?> {get}
    var isLoadingDriver: Driver<Bool> {get}
    var resetSignal: Signal<Void> {get}
    
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
        @Injected private var storage: AccountStorageType & PincodeStorageType & NameStorageType
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var notificationsService: NotificationsServiceType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private var isRestoration = false
        private var showAuthenticationOnMainOnAppear = true
        private var resolvedName: String?
        
        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let isLoadingSubject = BehaviorRelay<Bool>(value: false)
        private let resetSubject = PublishRelay<Void>()
        
        // MARK: - Actions
        func reload() {
            // signal VC to prepare for reseting
            resetSubject.accept(())
            
            // reload session
            ResolverScope.session.reset()
            
            // mark as loading
            isLoadingSubject.accept(true)
            
            // try to retrieve account from seed
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                let account = self?.storage.account
                DispatchQueue.main.async { [weak self] in
                    if account == nil {
                        self?.showAuthenticationOnMainOnAppear = false
                        self?.navigationSubject.accept(.createOrRestoreWallet)
                    } else if self?.storage.pinCode == nil ||
                                !Defaults.didSetEnableBiometry ||
                                !Defaults.didSetEnableNotifications
                    {
                        self?.showAuthenticationOnMainOnAppear = false
                        self?.navigationSubject.accept(.onboarding)
                    } else {
                        self?.navigationSubject.accept(.main(showAuthenticationWhenAppears: self?.showAuthenticationOnMainOnAppear ?? false))
                    }
                }
            }
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
    
    var resetSignal: Signal<Void> {
        resetSubject.asSignal()
    }
}

extension Root.ViewModel: DeviceOwnerAuthenticationHandler {
    func requiredOwner(onSuccess: (() -> Void)?, onFailure: ((String?) -> Void)?) {
        let myContext = LAContext()
        
        var error: NSError?
        guard myContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            DispatchQueue.main.async {
                onFailure?(errorToString(error))
            }
            return
        }
        
        myContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: L10n.confirmItSYou) { (success, error) in
            guard success else {
                DispatchQueue.main.async {
                    onFailure?(errorToString(error))
                }
                return
            }
            DispatchQueue.main.sync {
                onSuccess?()
            }
        }
    }
}

extension Root.ViewModel: ChangeNetworkResponder {
    func changeAPIEndpoint(to endpoint: SolanaSDK.APIEndPoint) {
        Defaults.apiEndPoint = endpoint
        
        showAuthenticationOnMainOnAppear = false
        reload()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.notificationsService.showInAppNotification(.done(L10n.networkChanged))
        }
    }
}

extension Root.ViewModel: ChangeLanguageResponder {
    func languageDidChange(to language: LocalizedLanguage) {
        UIApplication.languageChanged()
        
        showAuthenticationOnMainOnAppear = false
        reload()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            let languageChangedText = language.originalName.map(L10n.changedLanguageTo) ?? L10n.interfaceLanguageChanged
            self?.notificationsService.showInAppNotification(.done(languageChangedText))
        }
    }
}

extension Root.ViewModel: LogoutResponder {
    func logout() {
        storage.clearAccount()
        Defaults.walletName = [:]
        Defaults.didSetEnableBiometry = false
        Defaults.didSetEnableNotifications = false
        Defaults.didBackupOffline = false
        Defaults.renVMSession = nil
        Defaults.renVMProcessingTxs = []
        Defaults.forceCloseNameServiceBanner = false
        Defaults.shouldShowConfirmAlertOnSend = true
        Defaults.shouldShowConfirmAlertOnSwap = true
        reload()
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
                try self?.storage.save(phrases: phrases)
                try self?.storage.save(derivableType: derivablePath.type)
                try self?.storage.save(walletIndex: derivablePath.walletIndex)
                
                if let name = name {
                    self?.storage.save(name: name)
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.isLoadingSubject.accept(false)
                }
            } catch {
                self?.isLoadingSubject.accept(false)
                DispatchQueue.main.async { [weak self] in
                    self?.notificationsService.showInAppNotification(.error(error))
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

private func errorToString(_ error: Error?) -> String? {
    var error = error?.localizedDescription ?? L10n.unknownError
    switch error {
    case "Passcode not set.":
        error = L10n.PasscodeNotSet.soWeCanTVerifyYouAsTheDeviceSOwner
    case "Canceled by user.":
        return nil
    default:
        break
    }
    return error
}
