//
//  TransactionImageView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/04/2021.
//

import Foundation
import RxSwift
import SolanaSwift
import UIKit

final class TransactionImageView: BEView {
    private let _backgroundColor: UIColor?
    private let _cornerRadius: CGFloat?
    private let basicIconSize: CGFloat
    private let miniIconsSize: CGFloat

    private lazy var basicIconImageView = UIImageView(
        width: basicIconSize,
        height: basicIconSize,
        tintColor: .iconSecondary
    )
    private lazy var fromTokenImageView = CoinLogoImageView(size: miniIconsSize)
    private lazy var toTokenImageView = CoinLogoImageView(size: miniIconsSize)

    init(
        size: CGFloat,
        backgroundColor: UIColor? = nil,
        cornerRadius: CGFloat? = nil,
        basicIconSize: CGFloat = 24.38,
        miniIconsSize: CGFloat = 30
    ) {
        _backgroundColor = backgroundColor
        _cornerRadius = cornerRadius
        self.basicIconSize = basicIconSize
        self.miniIconsSize = miniIconsSize
        super.init(frame: .zero)
        configureForAutoLayout()
        autoSetDimensions(to: .init(width: size, height: size))
    }

    override func commonInit() {
        super.commonInit()
        let backgroundView = UIView(backgroundColor: _backgroundColor, cornerRadius: _cornerRadius)
        addSubview(backgroundView)
        backgroundView.autoPinEdgesToSuperviewEdges()

        addSubview(basicIconImageView)
        basicIconImageView.autoCenterInSuperview()

        addSubview(fromTokenImageView)
        fromTokenImageView.autoPinToTopLeftCornerOfSuperview()

        addSubview(toTokenImageView)
        toTokenImageView.autoPinToBottomRightCornerOfSuperview()

        fromTokenImageView.alpha = 0
        toTokenImageView.alpha = 0
    }

    func setUp(imageType: ImageType) {
        switch imageType {
        case let .oneImage(image):
            fromTokenImageView.alpha = 0
            toTokenImageView.alpha = 0
            basicIconImageView.isHidden = false
            basicIconImageView.image = image
        case let .fromOneToOne(from, to):
            basicIconImageView.isHidden = true
            fromTokenImageView.alpha = 1
            toTokenImageView.alpha = 1
            fromTokenImageView.setUp(token: from)
            toTokenImageView.setUp(token: to)
        }
    }
}

// MARK: - Model

extension TransactionImageView {
    enum ImageType {
        case oneImage(image: UIImage)
        case fromOneToOne(from: SolanaSDK.Token?, to: SolanaSDK.Token?)
    }
}

// MARK: - Reactive

extension Reactive where Base == TransactionImageView {
    var imageType: Binder<Base.ImageType> {
        Binder(base) { $0.setUp(imageType: $1) }
    }
}
