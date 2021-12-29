//
//  SendToken.ChooseTokenAndAmount.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import Foundation
import UIKit
import Resolver

extension SendToken.ChooseTokenAndAmount {
    class ViewController: SendToken.BaseViewController {
        // MARK: - Dependencies
        private let viewModel: SendTokenChooseTokenAndAmountViewModelType
        @Injected var chooseWalletViewModelFactory: ChooseWalletViewModelFactoryType
        
        // MARK: - Properties
        
        // MARK: - Initializer
        init(
            viewModel: SendTokenChooseTokenAndAmountViewModelType
        ) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            navigationBar.titleLabel.text = L10n.send
            navigationBar.backButton.onTap(self, action: #selector(_back))
            navigationBar.rightItems.addArrangedSubview(
                UILabel(text: L10n.next.uppercaseFirst, textSize: 17, textColor: .h5887ff)
                    .onTap(self, action: #selector(buttonNextDidTouch))
            )
            
            let rootView = RootView(viewModel: viewModel)
            view.addSubview(rootView)
            rootView.autoPinEdge(.top, to: .bottom, of: navigationBar)
            rootView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: {[weak self] in self?.navigate(to: $0)})
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else {return}
            switch scene {
            case .chooseWallet:
                let viewModel = chooseWalletViewModelFactory.create(
                    selectedWallet: nil,
                    handler: viewModel,
                    showOtherWallets: false,
                    customFilter: { $0.amount > 0 }
                )
                let vc = ChooseWallet.ViewController(title: nil, viewModel: viewModel)
                present(vc, animated: true, completion: nil)
            case .backToConfirmation:
                navigationController?.popToViewController(ofClass: SendToken.ConfirmViewController.self, animated: true)
            case .invalidTokenForSelectedNetworkAlert:
                showAlert(
                    title: L10n.changeTheToken,
                    message: L10n.ifTheTokenIsChangedToTheAddressFieldMustBeFilledInWithA(
                        viewModel.getSelectedWallet()?.token.symbol ?? "",
                        L10n.compatibleAddress(L10n.solana)
                    ),
                    buttonTitles: [L10n.discard, L10n.change],
                    highlightedButtonIndex: 1,
                    destroingIndex: 0
                ) {[weak self] selectedIndex in
                    guard selectedIndex == 1 else {return}
                    self?.viewModel.save()
                    self?.viewModel.navigateNext()
                }
            }
        }
        
        @objc override func _back() {
            if viewModel.showAfterConfirmation {
                back()
            } else {
                viewModel.cancelSending()
            }
        }
        
        @objc private func buttonNextDidTouch() {
            if viewModel.isTokenValidForSelectedNetwork() {
                viewModel.save()
                viewModel.navigateNext()
            }
        }
    }
}
