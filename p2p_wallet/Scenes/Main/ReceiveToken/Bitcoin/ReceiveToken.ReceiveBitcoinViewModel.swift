//
//  ReceiveToken.ReceiveBitcoinViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/09/2021.
//

import RenVMSwift
import Resolver
import RxCocoa
import RxSwift

protocol ReceiveTokenBitcoinViewModelType: AnyObject {
    var addressDriver: Driver<String?> { get }
    var timerSignal: Signal<Void> { get }
    var processingTxsDriver: Driver<[RenVM.LockAndMint.ProcessingTx]> { get }
    var hasExplorerButton: Bool { get }

    func getSessionEndDate() -> Date?
    func acceptConditionAndLoadAddress()
    func showReceivingStatuses()
    func copyToClipboard()
    func share(image: UIImage)
    func saveAction(image: UIImage)
    func showBTCAddressInExplorer()
}

extension ReceiveToken {
    class ReceiveBitcoinViewModel {
        // MARK: - Constants

        private let disposeBag = DisposeBag()
        let hasExplorerButton: Bool

        // MARK: - Dependencies

        @Injected private var renVMService: RenVMLockAndMintServiceType
        @Injected private var analyticsManager: AnalyticsManagerType
        @Injected private var clipboardManager: ClipboardManagerType
        @Injected private var imageSaver: ImageSaverType
        @Injected var notificationsService: NotificationService
        private let navigationSubject: PublishRelay<NavigatableScene?>

        // MARK: - Subjects

        private let timerSubject = PublishRelay<Void>()

        // MARK: - Initializers

        init(
            navigationSubject: PublishRelay<NavigatableScene?>,
            hasExplorerButton: Bool
        ) {
            self.navigationSubject = navigationSubject
            self.hasExplorerButton = hasExplorerButton

            bind()
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        func acceptConditionAndLoadAddress() {
            renVMService.loadSession()
        }

        private func bind() {
            Timer.observable(seconds: 1)
                .bind(to: timerSubject)
                .disposed(by: disposeBag)

            timerSubject
                .subscribe(onNext: { [weak self] in
                    guard let endAt = self?.getSessionEndDate() else { return }
                    if Date() >= endAt {
                        self?.renVMService.expireCurrentSession()
                    }
                })
                .disposed(by: disposeBag)
        }
    }
}

extension ReceiveToken.ReceiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType {
    var addressDriver: Driver<String?> {
        renVMService.addressDriver
    }

    var timerSignal: Signal<Void> {
        timerSubject.asSignal()
    }

    var processingTxsDriver: Driver<[RenVM.LockAndMint.ProcessingTx]> {
        renVMService.processingTxsDriver
    }

    func getSessionEndDate() -> Date? {
        renVMService.getSessionEndDate()
    }

    func copyToClipboard() {
        guard let address = renVMService.getCurrentAddress() else { return }
        clipboardManager.copyToClipboard(address)
        notificationsService.showInAppNotification(.done(L10n.addressCopiedToClipboard))
        analyticsManager.log(event: .receiveAddressCopied)
    }

    func share(image: UIImage) {
        analyticsManager.log(event: .receiveAddressShare)
        navigationSubject.accept(
            .share(address: renVMService.getCurrentAddress() ?? "", qrCode: image)
        )
    }

    func saveAction(image: UIImage) {
        analyticsManager.log(event: .receiveQRSaved)
        imageSaver.save(image: image) { [weak self] result in
            switch result {
            case .success:
                self?.notificationsService.showInAppNotification(.done(L10n.savedToPhotoLibrary))
            case let .failure(error):
                switch error {
                case .noAccess:
                    self?.navigationSubject.accept(.showPhotoLibraryUnavailable)
                case .restrictedRightNow:
                    break
                case let .unknown(error):
                    self?.notificationsService.showInAppNotification(.error(error))
                }
            }
        }
    }

    func showBTCAddressInExplorer() {
        guard let address = renVMService.getCurrentAddress() else { return }
        analyticsManager.log(event: .receiveViewingExplorer)
        navigationSubject.accept(.showBTCExplorer(address: address))
    }

    func showReceivingStatuses() {
        navigationSubject.accept(.showRenBTCReceivingStatus)
    }
}
