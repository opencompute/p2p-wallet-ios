//
//  SelectRecipient.RecipientsCollectionView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/10/2021.
//

import Foundation
import BECollectionView

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    final class RecipientsCollectionView: BEStaticSectionsCollectionView {
        // MARK: - Dependencies
        private let recipientsListViewModel: RecipientsListViewModel
        
        // MARK: - Initializer
        init(recipientsListViewModel: RecipientsListViewModel) {
            self.recipientsListViewModel = recipientsListViewModel
            
            let section = BEStaticSectionsCollectionView.Section(
                index: 0,
                layout: .init(
                    cellType: RecipientCell.self,
                    itemHeight: .estimated(76)
                ),
                viewModel: recipientsListViewModel
            )
            
            super.init(sections: [section])
        }
    }
}
