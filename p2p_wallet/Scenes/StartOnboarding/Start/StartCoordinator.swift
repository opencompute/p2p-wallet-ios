import Combine
import SwiftUI

enum StartCoordinatorNavigation {
    case root(window: UIWindow)
    case push(nc: UINavigationController)
}

final class StartCoordinator: Coordinator<Void> {
    private let navigation: StartCoordinatorNavigation
    private weak var viewController: UIViewController?
    private var subject = PassthroughSubject<Void, Never>()

    // MARK: - Initializer

    init(navigation: StartCoordinatorNavigation) {
        self.navigation = navigation
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = StartViewModel()
        let viewController = UIHostingController(rootView: StartView(viewModel: viewModel))
        self.viewController = viewController

        switch navigation {
        case let .root(window):
            let navigationController = UINavigationController(rootViewController: viewController)
            style(nc: navigationController)
            window.animate(newRootViewController: navigationController)
        case let .push(nc):
            nc.delegate = self
            nc.pushViewController(viewController, animated: true)
        }

        viewModel.$navigatableScene.sink { [weak self] scene in
            guard let self = self else { return }
            switch scene {
            case .restoreWallet:
                self.openRestoreWallet(vc: viewController)
            case .createWallet:
                self.openCreateWallet(vc: viewController)
            case .mockContinue:
                self.openContinue(vc: viewController)
            case .none:
                break
            }
        }.store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }

    private func openCreateWallet(vc: UIViewController) {
        coordinate(to: CreateWalletCoordinator(parent: vc))
            .sink { _ in }.store(in: &subscriptions)
    }

    private func openRestoreWallet(vc: UIViewController) {
        coordinate(to: RestoreWalletCoordinator(parent: vc))
            .sink { _ in }.store(in: &subscriptions)
    }

    // TODO: Mock method
    private func openContinue(vc _: UIViewController) {
        switch navigation {
        case let .root(window):
            coordinate(to: ContinueCoordinator(window: window))
                .sink(receiveValue: {}).store(in: &subscriptions)
        case let .push(nc):
            break
        }
    }

    private func style(nc: UINavigationController) {
        nc.navigationBar.setBackgroundImage(UIImage(), for: .default)
        nc.navigationBar.shadowImage = UIImage()
        nc.navigationBar.isTranslucent = true
    }
}

// MARK: - UINavigationControllerDelegate

extension StartCoordinator: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated _: Bool
    ) {
        guard let currentVC = self.viewController, viewController != currentVC else { return }
        if navigationController.viewControllers.contains(where: { $0 == currentVC }) == false {
            subject.send(completion: .finished)
        }
    }
}
