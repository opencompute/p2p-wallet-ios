import Combine
import Send
import SolanaSwift
import SwiftUI

final class SendInputCoordinator: Coordinator<SendResult> {
    private let navigationController: UINavigationController
    private let recipient: Recipient
    private let preChosenWallet: Wallet?
    private var subject = PassthroughSubject<SendResult, Never>()

    init(recipient: Recipient, preChosenWallet: Wallet?, navigationController: UINavigationController) {
        self.recipient = recipient
        self.preChosenWallet = preChosenWallet
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<SendResult, Never> {
        let viewModel = SendInputViewModel(recipient: recipient, preChosenWallet: preChosenWallet)
        let view = SendInputView(viewModel: viewModel)
        let controller = KeyboardAvoidingViewController(rootView: view)

        navigationController.pushViewController(controller, animated: true)
        setTitle(to: controller)

        controller.onClose = { [weak self] in
            self?.subject.send(.cancelled)
        }

        viewModel.tokenViewModel.changeTokenPressed
            .sink { [weak self] in
                self?.openChooseWalletToken(from: controller, viewModel: viewModel)
            }
            .store(in: &subscriptions)

        viewModel.openFeeInfo
            .sink { [weak self] isFree in
                if isFree {
                    self?.openFreeTransactionsDetail(from: controller)
                } else {
                    self?.openFeeDetail(from: controller, viewModel: viewModel)
                }
            }
            .store(in: &subscriptions)

        viewModel.snackbar
            .sink { snackbar in
                snackbar.show(in: controller.navigationController?.view ?? controller.view)
            }
            .store(in: &subscriptions)

        viewModel.transaction
            .sink { [weak self] model in
                self?.subject.send(.sent(model))
            }
            .store(in: &subscriptions)

        return subject.prefix(1).eraseToAnyPublisher()
    }

    private func setTitle(to vc: UIViewController) {
        switch recipient.category {
        case let .username(name, domain):
            if domain.isEmpty {
                vc.title = "@\(name)"
            } else {
                vc.title = "@\([name, domain].joined(separator: "."))"
            }
        default:
            vc.title = "\(recipient.address.prefix(7))...\(recipient.address.suffix(7))"
        }
        vc.navigationItem.largeTitleDisplayMode = .always
        vc.navigationController?.navigationBar.prefersLargeTitles = true
    }

    private func openChooseWalletToken(from vc: UIViewController, viewModel: SendInputViewModel) {
        coordinate(to: ChooseWalletTokenCoordinator(strategy: .sendToken, chosenWallet: viewModel.sourceWallet,
                                                    parentController: vc))
            .sink { walletToken in
                if let walletToken = walletToken {
                    viewModel.sourceWallet = walletToken
                }
            }
            .store(in: &subscriptions)
    }

    private func openFreeTransactionsDetail(from vc: UIViewController) {
        coordinate(to: SendInputFreeTransactionsDetailCoordinator(parentController: vc))
            .sink(receiveValue: {})
            .store(in: &subscriptions)
    }

    private func openFeePropmt(from vc: UIViewController, viewModel: SendInputViewModel) {
        guard let feeToken = viewModel.currentState.feeWallet else { return }
        coordinate(to: SendInputFeePromptCoordinator(
            parentController: vc,
            currentToken: viewModel.sourceWallet,
            feeToken: feeToken,
            feeInSOL: viewModel.currentState.fee
        ))
        .sink(receiveValue: { feeToken in
            guard let feeToken = feeToken else { return }
            viewModel.changeFeeToken.send(feeToken)
        })
        .store(in: &subscriptions)
    }

    private func openFeeDetail(from vc: UIViewController, viewModel: SendInputViewModel) {
        guard let feeToken = viewModel.currentState.feeWallet else { return }
        coordinate(to: SendTransactionDetailsCoordinator(
            parentController: vc,
            sendInputViewModel: viewModel
        ))
        .sink { result in
            switch result {
            case .redirectToFeePrompt:
                self.openFeePropmt(from: vc, viewModel: viewModel)
            }
        }
        .store(in: &subscriptions)
    }
}
