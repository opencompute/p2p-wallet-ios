//
//  Features.swift
//  FeatureFlags
//
//  Created by Babich Ivan on 10.06.2022.
//

public extension Feature {
    static let sslPinning = Feature(rawValue: "ssl_pinning")
    static let coinGeckoPriceProvider = Feature(rawValue: "coinGeckoPriceProvider")
    static let buyScenarioEnabled = Feature(rawValue: "keyapp_buy_scenario_enabled")
}
