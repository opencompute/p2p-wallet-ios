# P2P Wallet
P2P Wallet on Solana blockchain

## Features

- [x] Create new wallet
- [x] Restore existing wallet using seed phrases
- [x] Decentralized identification (name service)
- [x] Send SOL, SPL tokens and renBTC via name or address
- [x] Receive SOL, SPL tokens and renBTC
- [x] Swap SOL and SPL tokens (powered by Orca)
- [ ] Buy tokens (moonpay)

## Requirements

- iOS 13.0+
- Xcode 12

## Installation

#### Add Config.xconfig (ask team manager or use fake key below)
```
// MARK: - Transak
TRANSAK_STAGING_API_KEY = fake_api_key
TRANSAK_PRODUCTION_API_KEY = fake_api_key
TRANSAK_HOST_URL = p2p.org

// Mark: - Moonpay
MOONPAY_STAGING_API_KEY = fake_api_key
MOONPAY_PRODUCTION_API_KEY = fake_api_key

// MARK: - Amplitude
AMPLITUDE_API_KEY = fake_api_key

// MARK: - FeeRelayer
FEE_RELAYER_ENDPOINT = fee-relayer.solana.p2p.org
```

#### Install dependencies (cocoapods)
- Clone project and retrieve all submodules
```zsh
git clone git@github.com:p2p-org/p2p-wallet-ios.git
git submodule update --init --recursive
```
- Override `githook` directory:
```zsh
git config core.hooksPath .githooks
chmod -R +x .githooks
```
- Run `pod install`
- Run `swiftgen` for the first time
```zsh
Pods/swiftgen/bin/swiftgen config run --config swiftgen.yml
```

## Contribute

We would love you for the contribution to **P2P Wallet**, check the ``LICENSE`` file for more info.
