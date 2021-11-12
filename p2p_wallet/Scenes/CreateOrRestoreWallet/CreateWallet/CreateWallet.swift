//
//  CreateWallet.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/09/2021.
//

import Foundation

struct CreateWallet {
    enum NavigatableScene {
        case termsAndConditions
        case explanation
        case createPhrases
        case reserveName(owner: String)
        case dismiss
        case back
    }
}
