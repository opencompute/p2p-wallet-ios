//
//  File.swift
//  
//
//  Created by Chung Tran on 23/12/2022.
//

import Foundation
import Moonpay

extension Moonpay.Provider {
    func sellTransactions(externalCustomerId: String) async throws -> [MoonpaySellDataServiceProvider.MoonpayTransaction] {
        var components = URLComponents(string: serverSideAPI.endpoint + "api/v3/sell_transactions")!
        let params = ["apiKey": api.apiKey, "externalCustomerId": externalCustomerId]
        components.queryItems = params.map { key, value in
            URLQueryItem(name: key, value: value)
        }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        let urlRequest = URLRequest(url: components.url!)

        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        return try JSONDecoder().decode([MoonpaySellDataServiceProvider.MoonpayTransaction].self, from: data)
    }

    func sellTransaction(id: String) async throws -> MoonpaySellDataServiceProvider.MoonpayTransaction {
        var components = URLComponents(string: api.endpoint + "v3/sell_transactions/\(id)")!
        let params = ["apiKey": api.apiKey]
        components.queryItems = params.map { key, value in
            URLQueryItem(name: key, value: value)
        }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        let urlRequest = URLRequest(url: components.url!)
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        return try JSONDecoder().decode(MoonpaySellDataServiceProvider.MoonpayTransaction.self, from: data)
    }

    func deleteSellTransaction(id: String) async throws {
        let components = URLComponents(string: serverSideAPI.endpoint + "api/v3/sell_transactions/\(id)")!
        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "DELETE"
        let (_, response) = try await URLSession.shared.data(for: urlRequest)
        guard let code = (response as? HTTPURLResponse)?.statusCode, (200...299).contains(code) else {
            throw Moonpay.MoonpayProviderError.unknown
        }
    }
}
