import AnalyticsManager
import Combine
import Foundation
import KeyAppKitCore
import KeyAppUI
import Onboarding
import OrcaSwapSwift
import Resolver
import Sell
import Sentry
import SolanaSwift
import UIKit
import BEPureLayout

final class AppCoordinator: Coordinator<Void> {
    // MARK: - Dependencies

    private var appEventHandler: AppEventHandlerType = Resolver.resolve()
    private let storage: AccountStorageType & PincodeStorageType & NameStorageType = Resolver.resolve()
    let analyticsManager: AnalyticsManager = Resolver.resolve()
    let notificationsService: NotificationService = Resolver.resolve()

    @Injected var notificationService: NotificationService
    @Injected var userWalletManager: UserWalletManager
    @Injected var createNameService: CreateNameService

    // MARK: - Properties

    var window: UIWindow?
    var showAuthenticationOnMainOnAppear = true

    var reloadEvent = PassthroughSubject<Void, Never>()

    private var walletCreated: Bool = false

    // MARK: - Initializers

    override init() {
        super.init()
        defer { appEventHandler.delegate = self }
        bind()
    }

    // MARK: - Methods

    /// Starting point for coordinator
    func start() {
        // set window
        window = UIWindow(frame: UIScreen.main.bounds)

        // set appearance
        window?.overrideUserInterfaceStyle = Defaults.appearance

        // open splash and wait for data
        openSplash { [unowned self] in
            userWalletManager
                .$wallet
                .combineLatest(
                    reloadEvent
                        .map { _ in }
                        .prepend(())
                )
                .receive(on: RunLoop.main)
                .sink { [unowned self] wallet, _ in
                    if let wallet {
                        sendUserIdentifierToAnalyticsProviders(wallet)
                        if walletCreated, available(.onboardingUsernameEnabled) {
                            walletCreated = false
                            navigateToCreateUsername()
                        } else {
                            navigateToMain()
                        }
                    } else {
                        sendUserIdentifierToAnalyticsProviders(nil)
                        navigateToOnboardingFlow()
                    }
                }
                .store(in: &subscriptions)
        }
    }

    // MARK: - Navigation

    /// Open splash scene and wait for loading
    private func openSplash(_ completionHandler: @escaping () -> Void) {
        // TODO: - Return for new splash screen
        // let vc = SplashViewController()
        // window?.rootViewController = vc
        // window?.makeKeyAndVisible()

        let vc = BaseVC()
        let lockView = LockView()
        vc.view.addSubview(lockView)
        lockView.autoPinEdgesToSuperviewEdges()
        window?.rootViewController = vc
        window?.makeKeyAndVisible()

        // warmup
        Task {
            await Resolver.resolve(WarmupManager.self).start()
            try await userWalletManager.refresh()

            // if let splashVC = window?.rootViewController as? SplashViewController {
            //     splashVC.stop(completionHandler: completionHandler)
            // } else {
            completionHandler()
            // }
        }
    }

    /// Navigate to CreateUserName scene
    private func navigateToCreateUsername() {
        guard let window = window else { return }
        coordinate(to: CreateUsernameCoordinator(navigationOption: .onboarding(window: window)))
            .sink { [unowned self] in
                self.navigateToMain()
            }.store(in: &subscriptions)
    }

    /// Navigate to Main scene
    private func navigateToMain() {
        guard let window = window else { return }

        Task.detached {
            await Resolver.resolve(WalletMetadataService.self).synchronize()
        }

        Task {
            try await Resolver.resolve(OrcaSwapType.self).load()
        }

        Task {
            await Resolver.resolve(JupiterTokensRepository.self).load()
        }

        Task {
            // load services
            if available(.sellScenarioEnabled) {
                await Resolver.resolve((any SellDataService).self).checkAvailability()
            }

            // coordinate
            await MainActor.run { [unowned self] in
                let coordinator = TabBarCoordinator(
                    window: window,
                    authenticateWhenAppears: showAuthenticationOnMainOnAppear
                )
                coordinate(to: coordinator)
                    .sink(receiveValue: {})
                    .store(in: &subscriptions)
            }
        }
    }

    /// Navigate to onboarding flow if user is not yet created
    private func navigateToOnboardingFlow() {
        guard let window = window else { return }
        let provider = Resolver.resolve(StartOnboardingNavigationProvider.self)
        let startCoordinator = provider.startCoordinator(for: window)

        coordinate(to: startCoordinator)
            .sinkAsync(receiveValue: { [unowned self] result in
                GlobalAppState.shared.shouldPlayAnimationOnHome = true
                showAuthenticationOnMainOnAppear = false
                let userWalletManager: UserWalletManager = Resolver.resolve()
                switch result {
                case let .created(data):
                    walletCreated = true

                    analyticsManager.log(event: .setupOpen(fromPage: "create_wallet"))
                    analyticsManager.log(event: .createConfirmPin(result: true))

                    saveSecurity(data: data.security)
                    // Setup user wallet
                    try await userWalletManager.add(
                        seedPhrase: data.wallet.seedPhrase.components(separatedBy: " "),
                        derivablePath: data.wallet.derivablePath,
                        name: nil,
                        deviceShare: data.deviceShare,
                        ethAddress: data.ethAddress
                    )

                case let .restored(data):
                    analyticsManager.log(event: .restoreConfirmPin(result: true))

                    let restoreMethod: String = data.metadata == nil ? "seed" : "web3auth"
                    analyticsManager.log(parameter: .userRestoreMethod(restoreMethod))

                    saveSecurity(data: data.security)
                    // Setup user wallet
                    try await userWalletManager.add(
                        seedPhrase: data.wallet.seedPhrase.components(separatedBy: " "),
                        derivablePath: data.wallet.derivablePath,
                        name: nil,
                        deviceShare: nil,
                        ethAddress: data.ethAddress
                    )

                case .breakProcess:
                    navigateToOnboardingFlow()
                }
            })
            .store(in: &subscriptions)
    }

    // MARK: - Helper

    private func sendUserIdentifierToAnalyticsProviders(_ wallet: UserWallet?) {
        // Amplitude
        let amplitudeAnalyticsProvider: AmplitudeAnalyticsProvider = Resolver.resolve()
        amplitudeAnalyticsProvider.setUserId(wallet?.account.publicKey.base58EncodedString)

        // Sentry
        if let wallet {
            var sentryUser = Sentry.User(
                userId: wallet.account.publicKey.base58EncodedString
            )
            sentryUser.username = wallet.name
            SentrySDK.setUser(sentryUser)
        } else {
            SentrySDK.setUser(nil)
        }
    }

    private func saveSecurity(data: SecurityData) {
        Resolver.resolve(PincodeStorageType.self).save(data.pincode)
        Defaults.isBiometryEnabled = data.isBiometryEnabled
    }

    private func hideLoadingAndTransitionTo(_ vc: UIViewController) {
        window?.rootViewController?.view.hideLoadingIndicatorView()
        window?.animate(newRootViewController: vc)
    }

    private func bind() {
        createNameService.createNameResult
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSuccess in
                if isSuccess {
                    guard let view = self?.window?.rootViewController?.view else { return }
                    SnackBar(title: "🎉", icon: nil, text: L10n.nameWasBooked).show(in: view)
                } else {
                    self?.notificationService.showDefaultErrorNotification()
                }
            }.store(in: &subscriptions)
    }
}
