//
//  Authentication.ViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/11/2021.
//

import Foundation
import UIKit
import LocalAuthentication
import BEPureLayout

extension Authentication {
    class ViewController: BaseVC {
        // MARK: - Dependencies
        @Injected private var viewModel: AuthenticationViewModelType
        
        // MARK: - Properties
        override var title: String? { didSet { pincodeVC.title = title } }
        var isIgnorable: Bool = false { didSet { pincodeVC.isIgnorable = isIgnorable } }
        var useBiometry: Bool = true { didSet { pincodeVC.useBiometry = useBiometry } }
        
        // MARK: - Callbacks
        var onSuccess: (() -> Void)?
        var onCancel: (() -> Void)?
        
        // MARK: - Subscenes
        private lazy var pincodeVC: PincodeViewController = {
            let pincodeVC = PincodeViewController()
            pincodeVC.onSuccess = {[weak self] in
                self?.authenticationDidComplete()
            }
            pincodeVC.onCancel = {[weak self] in
                self?.cancel()
            }
            pincodeVC.didTapResetPincodeWithASeedPhraseButton = {[weak self] in
                self?.viewModel.showResetPincodeWithASeedPhrase()
            }
            return pincodeVC
        }()
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            add(child: pincodeVC)
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
            case .resetPincodeWithASeedPhrase:
                let vc = ResetPinCodeWithSeedPhrases.ViewController()
                vc.completion = {[weak self] in
                    self?.viewModel.setBlockedTime(nil)
                    self?.authenticationDidComplete()
                }
                present(vc, animated: true, completion: nil)
            }
        }
        
        // MARK: - Actions
        @objc private func cancel() {
            onCancel?()
            dismiss(animated: true, completion: nil)
        }
        
        private func authenticationDidComplete() {
            onSuccess?()
            dismiss(animated: true, completion: nil)
        }
    }
}
