//
//  PT.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 24/12/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol PTViewModelType {
    var navigationDriver: Driver<PT.NavigatableScene?> {get}
    var transactionInfoDriver: Driver<PT.TransactionInfo> {get}
    var isSwapping: Bool {get}
    var transactionID: String? {get}
    
    func getTransactionDescription(withAmount: Bool) -> String
    
    func navigate(to scene: PT.NavigatableScene)
}

extension PT {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var authenticationHandler: AuthenticationHandler
        @Injected private var renVMBurnAndReleaseService: RenVMBurnAndReleaseServiceType
        
        // MARK: - Properties
        private let processingTransaction: ProcessingTransactionType
        
        // MARK: - Subjects
        private let transactionInfoSubject = BehaviorRelay<TransactionInfo>(value: .init(transactionId: nil, status: .sending))
        
        // MARK: - Initializer
        init(processingTransaction: ProcessingTransactionType) {
            self.processingTransaction = processingTransaction
        }
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
    }
}

extension PT.ViewModel: PTViewModelType {
    var navigationDriver: Driver<PT.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var transactionInfoDriver: Driver<PT.TransactionInfo> {
        transactionInfoSubject.asDriver()
    }
    
    var isSwapping: Bool {
        processingTransaction.isSwap
    }
    
    var transactionID: String? {
        transactionInfoSubject.value.transactionId
    }
    
    func getTransactionDescription(withAmount: Bool) -> String {
        switch processingTransaction {
        case let transaction as PT.SendTransaction:
            var desc = transaction.sender.token.symbol + " → " + (transaction.receiver.name ?? transaction.receiver.address.truncatingMiddle(numOfSymbolsRevealed: 4))
            if withAmount {
                let amount = transaction.amount.convertToBalance(decimals: transaction.sender.token.decimals)
                    .toString(maximumFractionDigits: 9)
                desc = amount + " " + desc
            }
            return desc
        default:
            return ""
        }
    }
    
    // MARK: - Actions
    func navigate(to scene: PT.NavigatableScene) {
        navigationSubject.accept(scene)
    }
}
