//
//  File.swift
//
//
//  Created by Giang Long Tran on 24.03.2023.
//

import Foundation
import SolanaSwift

public typealias SolanaToken = Token

extension SolanaToken: AnyToken {
    public var tokenPrimaryKey: String {
        isNative ? "native" : address
    }

    public var network: TokenNetwork {
        .solana
    }
}
