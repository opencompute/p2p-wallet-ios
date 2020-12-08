//
//  RestoreWalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/11/2020.
//

import Foundation

class RestoreWalletVC: IntroVCWithButtons {
    lazy var iCloudRestoreButton = WLButton.stepButton(type: .main, label: L10n.restoreUsingICloud)
        .onTap(self, action: #selector(buttonICloudRestoreDidTouch))
    lazy var restoreManuallyButton = WLButton.stepButton(type: .sub, label: L10n.restoreManually)
        .onTap(self, action: #selector(buttonRestoreManuallyDidTouch))
    
    override func setUp() {
        super.setUp()
        descriptionLabel.isHidden = false
        titleLabel.text = L10n.wowletRecovery
        descriptionLabel.text = L10n.recoverYourWowletUsingCloudServicesOrRecoverManually
        
        buttonStackView.addArrangedSubviews([
            iCloudRestoreButton,
            restoreManuallyButton
        ])
    }
    
    @objc func buttonICloudRestoreDidTouch() {
        guard let phrases = AccountStorage.shared.phrasesFromICloud() else
        {
            showAlert(title: L10n.noAccount, message: L10n.thereIsNoWowletSavedInYourICloud)
            return
        }
        handlePhrases(phrases)
    }
    
    @objc func buttonRestoreManuallyDidTouch() {
        let vc = EnterPhrasesVC()
        show(vc, sender: self)
    }
    
    private func handlePhrases(_ text: String)
    {
        do {
            let phrases = text.components(separatedBy: " ")
            _ = try Mnemonic(phrase: phrases.filter {!$0.isEmpty})
            let nc = BENavigationController(rootViewController: WelcomeBackVC(phrases: phrases))
            UIApplication.shared.changeRootVC(to: nc)
        } catch {
            showError(error)
        }
    }
}
