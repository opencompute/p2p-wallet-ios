//
//  File.swift
//
//
//  Created by Giang Long Tran on 21.03.2023.
//

import Foundation
import KeyAppKitCore
import SolanaSwift

public typealias SolanaToken = Token

extension SolanaToken: AnyToken {
    public var tokenPrimaryKey: String {
        return isNative ? "native-solana" : address
    }
}
