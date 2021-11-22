//
//  WalletDetail.InfoViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/11/2021.
//

import Foundation
import UIKit

extension WalletDetail {
    class InfoViewController: BaseVC {
        override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
            .hidden
        }
        
        // MARK: - Dependencies
        private let viewModel: WalletDetailViewModelType
        
        // MARK: - Subviews
        private lazy var overviewView = InfoOverviewView(viewModel: viewModel)
        lazy var lineChartView = ChartView()
        lazy var chartPicker: HorizontalPicker = {
            let chartPicker = HorizontalPicker(forAutoLayout: ())
            chartPicker.labels = Period.allCases.map {$0.shortString}
            chartPicker.selectedIndex = Period.allCases.firstIndex(where: {$0 == .last1h})!
            chartPicker.delegate = self
            return chartPicker
        }()
        
        // MARK: - Initializers
        init(viewModel: WalletDetailViewModelType) {
            self.viewModel = viewModel
            super.init()
        }
        
        // MARK: - Methods
        override func setUp() {
            super.setUp()
            let stackView = UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill) {
                overviewView
                lineChartView
                chartPicker
                UIView.spacer
            }
            view.addSubview(stackView)
            stackView.autoPinEdgesToSuperviewEdges(with: .init(all: 18, excludingEdge: .top))
            
            viewModel.graphViewModel.reload()
        }
        
        override func bind() {
            super.bind()
            lineChartView
                .subscribed(to: viewModel.graphViewModel)
                .disposed(by: disposeBag)
        }
    }
}

extension WalletDetail.InfoViewController: HorizontalPickerDelegate {
    func picker(_ picker: HorizontalPicker, didSelectOptionAtIndex index: Int) {
        guard index < Period.allCases.count else {return}
        viewModel.graphViewModel.period = Period.allCases[index]
        viewModel.graphViewModel.reload()
    }
}
