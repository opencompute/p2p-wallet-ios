//
//  ActivitiesVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/5/20.
//

import Foundation
import DiffableDataSources

class ActivitiesVC: CollectionVC<Activity, ActivityCell> {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle { .normal(backgroundColor: .vcBackground) }
    let wallet: Wallet
    
    // MARK: - Initializer
    init(wallet: Wallet) {
        self.wallet = wallet
        super.init(viewModel: ListViewModel<Activity>())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        title = wallet.name
        view.backgroundColor = .vcBackground
    }
    
    // MARK: - Layout
    override var sections: [Section] {
        [Section(headerViewClass: AVCSectionHeaderView.self, headerTitle: L10n.activities, interGroupSpacing: 16)]
    }
}
