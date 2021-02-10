//
//  WalletVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/2/20.
//

import Foundation
import Action
import RxSwift

enum MainVCItem: ListItemType {
    static func placeholder(at index: Int) -> MainVCItem {
        .wallet(Wallet.placeholder(at: index))
    }
    
    var id: String {
        switch self {
        case .wallet(let wallet):
            return "\(wallet.id)#wallet"
        case .friend:
            return "friend"
        }
    }
    case wallet(Wallet)
    case friend // TODO: - Friend
}

class MainVC: CollectionVC<MainVCItem> {
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {.hidden}
    var walletsVM: WalletsVM {WalletsVM.ofCurrentUser}
    let numberOfWalletsToShow = 4
    
    init() {
        let vm = MainVM()
        super.init(viewModel: vm)
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        view.backgroundColor = .white
        setStatusBarColor(.h1b1b1b)
    }
    
    // MARK: - Layout
    override var sections: [Section] {
        [
            Section(
                header: Section.Header(viewClass: FirstSectionHeaderView.self, title: ""),
                footer: Section.Footer(viewClass: FirstSectionFooterView.self),
                cellType: MainWalletCell.self,
                interGroupSpacing: 30,
                horizontalInterItemSpacing: NSCollectionLayoutSpacing.fixed(16),
                background: FirstSectionBackgroundView.self
            ),
            Section(
                header: Section.Header(viewClass: SecondSectionHeaderView.self, title: ""),
                cellType: FriendCell.self,
                background: SecondSectionBackgroundView.self
            )
        ]
    }
    
    override func mapDataToSnapshot() -> NSDiffableDataSourceSnapshot<String, MainVCItem> {
        // initial snapshot
        var snapshot = NSDiffableDataSourceSnapshot<String, MainVCItem>()
        
        // section 1
        let section = L10n.wallets
        snapshot.appendSections([section])
        
        var items = filterWallet(self.walletsVM.items).map {MainVCItem.wallet($0)}
        switch walletsVM.state.value {
        case .loading:
            items += [MainVCItem.placeholder(at: 0), MainVCItem.placeholder(at: 1)]
        case .loaded, .error, .initializing:
            break
        }
        snapshot.appendItems(items, toSection: section)
        
        // section 2
        let section2 = L10n.friends
        snapshot.appendSections([section2])
//        snapshot.appendItems([MainVCItem.friend], toSection: section2)
        return snapshot
    }
    
    override func setUpCell(cell: UICollectionViewCell, withItem item: MainVCItem) {
        switch item {
        case .wallet(let wallet):
            (cell as! MainWalletCell).setUp(with: wallet)
        case .friend:
            break
        }
    }
    
    override func configureHeaderForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let header = super.configureHeaderForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        
        switch indexPath.section {
        case 0:
            if let view = header as? FirstSectionHeaderView {
                view.openProfileAction = self.openProfile
            }
        case 1:
            if let view = header as? SecondSectionHeaderView {
                view.receiveAction = self.receiveAction
                view.sendAction = self.sendAction()
                view.exchangeAction = self.swapAction
            }
        default:
            break
        }
        
        return header
    }
    
    override func configureFooterForSectionAtIndexPath(_ indexPath: IndexPath, inCollectionView collectionView: UICollectionView) -> UICollectionReusableView? {
        let footer = super.configureFooterForSectionAtIndexPath(indexPath, inCollectionView: collectionView)
        
        switch indexPath.section {
        case 0:
            if let view = footer as? FirstSectionFooterView {
                view.showProductsAction = self.showAllProducts
            }
        default:
            break
        }
        
        return footer
    }
    
    // MARK: - Actions
    override func itemDidSelect(_ item: MainVCItem) {
        switch item {
        case .wallet(let wallet):
            present(WalletDetailVC(wallet: wallet), animated: true, completion: nil)
        default:
            break
        }
    }
    
    var receiveAction: CocoaAction {
        CocoaAction { _ in
            let wallets = self.walletsVM.items
            if wallets.count == 0 {return .just(())}
            let vc = ReceiveTokenVC(wallets: wallets)
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
    }
    
    func sendAction(address: String? = nil) -> CocoaAction {
        CocoaAction { _ in
            let wallets = self.walletsVM.items
            if wallets.count == 0 {return .just(())}
            let vm = SendTokenViewModel(wallets: wallets, activeWallet: nil, destinationAddress: address)
            let vc = SendTokenViewController(viewModel: vm)
            let titleImageView = UIImageView(width: 24, height: 24, image: .walletSend, tintColor: .white)
                .padding(.init(all: 6), backgroundColor: .h5887ff, cornerRadius: 12)
            self.presentCustomModal(vc: vc, title: L10n.send, titleImageView: titleImageView)
            return .just(())
        }
    }
    
    var swapAction: CocoaAction {
        CocoaAction { _ in
            let wallets = self.walletsVM.items
            if wallets.count == 0 {return .just(())}
            let vc = SwapTokenVC()
            self.present(vc, animated: true, completion: nil)
            return .just(())
        }
    }
    
    var showAllProducts: CocoaAction {
        CocoaAction { _ in
            self.present(MyProductsVC(), animated: true, completion: nil)
            return .just(())
        }
    }
    
    var openProfile: CocoaAction {
        CocoaAction { _ in
            self.present(ProfileVC(), animated: true, completion: nil)
            return .just(())
        }
    }
    
    // MARK: - Helpers
    func filterWallet(_ items: [Wallet]) -> [Wallet] {
        var wallets = [Wallet]()
        
        if let solWallet = items.first(where: {$0.symbol == "SOL"}) {
            wallets.append(solWallet)
        }
        wallets.append(
            contentsOf: items
                .filter {$0.symbol != "SOL"}
                .sorted(by: {$0.amountInUSD > $1.amountInUSD})
                .prefix(numberOfWalletsToShow - 1)
        )
        
        return wallets
    }
}
