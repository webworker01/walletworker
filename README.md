# WalletWorker 0.0.1a for Komodo

By [webworker01](https://webworker.sh/notary)

Please vote for me in the notary node elections by sending VOTE2018 to RPyD36pL25mRh4uNR2AaEHfoUjVHYDUbVe

## What is this?

This is a fancy batch file which creates a lightweight wallet interface for Komodo and all of its assetchains.  It sets up and depends on the "native" blockchains that you wish to operate with. I am not planning on implementing SPV(electrum) functionality at this time, if you desire this please use the excellent [Agama wallet](https://komodoplatform.com/komodo-wallets/).

## Why did you make this?

I wanted to create something for the Komodo community that I could bring to a useable state within a short amount of time. I also wanted to demonstrate my ability to work with the Komodo blockchain in an easily auditable way.  

While there are certainly limitations to creating a program with a batch file, I was inspired by [DeckerSU's dexscripts.win32](https://github.com/DeckerSU/SuperNET/blob/dev-decker-dev/iguana/dexscripts.win32/how_to_use.md) for BarterDEX and being a script, anyone with some basic programming knowledge can review exactly what the program is doing without trusting in a compiled binary.   I was also able to complete the initial version in a little under 24 hours of total work which was important for me right in the middle of the notary node elections!

## Features

* Auto installs and updates from https://artifacts.supernet.org/latest/windows/
* Handles Komodo and all assetchains
* Configurable data directory
* Implemented RPC calls
    * getnewaddress
    * getinfo
    * getaddressesbyaccount
    * listtransactions
    * z_listaddresses
    * z_getnewaddress

## Requirements

Developed and tested on Win10x64 but _should_ work with Windows 7.

Some features use PowerShell 2.0 functions which requires .NET Framework 2.0, but these should be installed with Windows 7 and up.

Any other requirements will come from komodod and komodo-cli, but if all goes well, these will be installed for you when you first start up the bat file.

## Potential Future Enhancements

I need to make sure everything is solid with the current features before adding on much more, but some thoughts:

* Better formatting of RPC results
* Wallet.dat encryption (This needs to be tested with Agama, but most likely will cause compatibility issues)
* Possibly some BarterDex integration
* [Bitcoin](https://bitcoin.org) and other BTC compatibles support
* Linux version

## Get in Touch

If you have any questions or comments, please feel free to reach out to me on the Komodo Slack or Telegram @webworker01

Pull requests are also welcome!

Please consider me during your voting for the Komodo Notary Node elections, this is just a small sample of what I can contribute to the community :)