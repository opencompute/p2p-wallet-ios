//
//  SwapSettingsView.swift
//  p2p_wallet
//
//  Created by Ivan on 28.02.2023.
//

import SwiftUI
import KeyAppUI
import SkeletonUI

struct SwapSettingsView: View {
    @ObservedObject var viewModel: SwapSettingsViewModel
    
    @State private var failureSlippage: Bool = false
    @State private var textFieldColor: UIColor = Asset.Colors.night.color
    
    var body: some View {
        List {
            Section {
                fisrtSectionRows
            }
            
            Section {
                commonRow(
                    title: L10n.minimumReceived,
                    subtitle: viewModel.info?.minimumReceived?.amountDescription
                )
            }
            
            Section(header: Text(L10n.slippage)) {
                slippageRows
            }
        }
    }
    
    // MARK: - First section

    private var fisrtSectionRows: some View {
        Group {
            // Route
            commonRow(
                title: L10n.swappingThrough,
                subtitle: viewModel.info?.currentRoute.tokensChain,
                trailingSubtitle: viewModel.info?.currentRoute.description,
                trailingView: Image(uiImage: .nextArrow)
                    .resizable()
                    .frame(width: 7.41, height: 12)
                    .padding(.vertical, (20-12)/2)
                    .padding(.horizontal, (20-7.41)/2)
                    .castToAnyView()
            )
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.navigateToSelectRoute()
                }
            
            // Network fee
            feeRow(
                title: L10n.networkFee,
                fee: viewModel.info?.networkFee,
                canBePaidByKeyApp: true
            )
            
            // Account creation fee
            feeRow(
                title: L10n.accountCreationFee,
                fee: viewModel.info?.accountCreationFee,
                canBePaidByKeyApp: false
            )
            
            // Liquidity fee
            feeRow(
                title: L10n.liquidityFee,
                fees: viewModel.info?.liquidityFee ?? []
            )
            
            // Estimated fee
            HStack {
                Text(L10n.estimatedFees)
                    .fontWeight(.semibold)
                    .apply(style: .text3)
                    .padding(.vertical, 10)
                
                Spacer()
                
                Text(viewModel.info?.estimatedFees)
                    .fontWeight(.semibold)
                    .apply(style: .text3)
                    .padding(.vertical, 10)
            }
                .frame(maxWidth: .infinity)
        }
            
    }
    
    private func feeRow(
        title: String,
        fee: SwapSettingsFeeInfo?,
        canBePaidByKeyApp: Bool
    ) -> some View {
        commonRow(
            title: title,
            subtitle: fee?.amountDescription,
            subtitleColor: fee?.shouldHighlightAmountDescription == true ? Asset.Colors.mint.color: Asset.Colors.mountain.color,
            trailingSubtitle: fee?.amountInFiatDescription
        )
    }
    
    private func feeRow(
        title: String,
        fees: [SwapSettingsFeeInfo]
    ) -> some View {
        commonRow(
            title: title,
            subtitle: fees.compactMap(\.amountDescription).joined(separator: ", "),
            trailingSubtitle: "≈ " + fees.compactMap(\.amountInFiat).reduce(0.0, +).fiatAmountFormattedString()
        )
    }
    
    private func commonRow(
        title: String,
        subtitle: String?,
        subtitleColor: UIColor = Asset.Colors.mountain.color,
        trailingSubtitle: String? = nil,
        isLoading: Bool = true,
        trailingView: AnyView = Image(uiImage: .infoStraight)
            .resizable()
            .foregroundColor(Color(Asset.Colors.mountain.color))
            .frame(width: 20, height: 20)
            .castToAnyView()
    ) -> some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .apply(style: .text3)
                Text(subtitle)
                    .apply(style: .label1)
                    .foregroundColor(Color(subtitleColor))
                    .skeleton(with: isLoading, size: .init(width: 100, height: 12))
            }
            
            Spacer()
            
            Text(trailingSubtitle)
                .apply(style: .label1)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .layoutPriority(1)
                .skeleton(with: isLoading, size: .init(width: 52, height: 16))
            
            trailingView
        }
        .frame(maxWidth: .infinity)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
    
    // MARK: - Slippage section

    private var slippageRows: some View {
        ForEach(Array(zip(viewModel.slippages.indices, viewModel.slippages)), id: \.0) { index, slippage in
            Button(
                action: {
                    viewModel.selectedIndex = index
                },
                label: {
                    if let slippage = slippage {
                        HStack {
                            Text("\(String(format: "%.1f", slippage))%")
                                .foregroundColor(Color(Asset.Colors.night.color))
                                .font(uiFont: .font(of: .text3))
                            Spacer()
                            if index == viewModel.selectedIndex {
                                Image(systemName: "checkmark")
                            }
                        }
                        .padding(.vertical, 16)
                    } else {
                        VStack {
                            HStack {
                                Text(L10n.custom)
                                    .foregroundColor(Color(Asset.Colors.night.color))
                                    .font(uiFont: .font(of: .text3))
                                Spacer()
                                if index == viewModel.selectedIndex {
                                    Image(systemName: "checkmark")
                                }
                            }
                            if index == viewModel.selectedIndex {
                                VStack(alignment: .leading, spacing: 4) {
                                    ZStack {
                                        Color(Asset.Colors.rain.color)
                                            .frame(height: 44)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        Color(Asset.Colors.rose.color),
                                                        lineWidth: failureSlippage ? 1 : 0
                                                    )
                                            )
                                        TextFieldWithSuffix(
                                            title: nil,
                                            text: $viewModel.slippage,
                                            textColor: $textFieldColor,
                                            becomeFirstResponder: $viewModel.customSelected
                                        )
                                        .padding(.horizontal, 16)
                                    }
                                    Text("\(L10n.theSlippageCouldBe) 0.01-50%")
                                        .foregroundColor(failureSlippage ? Color(Asset.Colors.rose.color) : Color(Asset.Colors.mountain.color))
                                        .font(uiFont: .font(of: .label1))
                                }
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            )
        }
        .onChange(of: viewModel.failureSlippage) { failureSlippage in
            textFieldColor = !failureSlippage ? Asset.Colors.night.color : Asset.Colors.rose.color
            self.failureSlippage = failureSlippage
        }
    }
}

struct SwapSettingsView_Previews: PreviewProvider {
    static let viewModel = SwapSettingsViewModel(
        status: .loading,
        slippage: 0.5
    )
    static var previews: some View {
        SwapSettingsView(viewModel: viewModel)
        .onAppear {
//            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
//                let info = SwapSettingsViewModel.Info(
//                    routes: [
//                        .init(
//                            id: "1",
//                            name: "Raydium",
//                            description: "Best price",
//                            tokensChain: "SOL→CLMM→USDC→CRAY"
//                        ),
//                        .init(
//                            name: "Raydium 95% + Orca 5%",
//                            description: "-0.0006 TokenB",
//                            tokensChain: "SOL→CLMM→USDC→CRAY"
//                        ),
//                        .init(
//                            name: "Raydium 95% + Orca 5%",
//                            description: "-0.0006 TokenB",
//                            tokensChain: "SOL→CLMM→USDC→CRAY"
//                        )
//                    ],
//                    currentRoute: .init(
//                        name: "Raydium",
//                        description: "Best price",
//                        tokensChain: "SOL→CLMM→USDC→CRAY"
//                    ),
//                    networkFee: .init(
//                        amount: 0,
//                        token: nil,
//                        amountInFiat: nil,
//                        canBePaidByKeyApp: true
//                    ),
//                    accountCreationFee: .init(
//                        amount: 0.8,
//                        token: "Token A",
//                        amountInFiat: 6.1,
//                        canBePaidByKeyApp: false
//                    ),
//                    liquidityFee: [
//                        .init(
//                            amount: 0.991,
//                            token: "TokenC",
//                            amountInFiat: 0.05,
//                            canBePaidByKeyApp: false
//                        ),
//                        .init(
//                            amount: 0.991,
//                            token: "TokenD",
//                            amountInFiat: 0.05,
//                            canBePaidByKeyApp: false
//                        )
//                    ],
//                    minimumReceived: .init(
//                        amount: 0.91,
//                        token: "TokenB"
//                    )
//                )
//
//                viewModel.status = .loaded(
//                    info
//                )
//            }
        }
    }
}
