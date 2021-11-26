//
//  DAppContainer.ViewController.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 25.11.21.
//

import Foundation
import UIKit

extension DAppContainer {
    class ViewController: BaseVC {
        // MARK: - Dependencies
        @Injected private var viewModel: DAppContainerViewModelType
        private var walletsRepository: WalletsRepository
        
        init(walletsRepository: WalletsRepository) {
            self.walletsRepository = walletsRepository
        }
        
        // MARK: - Properties
        
        // MARK: - Methods
        override func loadView() {
            view = RootView()
        }
        
        override func setUp() {
            super.setUp()
            
            viewModel.setup(walletsRepository: walletsRepository)
        }
        
        override func bind() {
            super.bind()
            viewModel.navigationDriver
                .drive(onNext: { [weak self] in self?.navigate(to: $0) })
                .disposed(by: disposeBag)
        }
        
        // MARK: - Navigation
        private func navigate(to scene: NavigatableScene?) {
            guard let scene = scene else { return }
            switch scene {
            case .detail:
//                let vc = Detail.ViewController()
//                present(vc, completion: nil)
                break
            }
        }
    }
}
