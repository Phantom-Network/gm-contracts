![GM.CO](img/GMHeader.jpg)

# GM Marketplace

## Table of Contents

- [GM Marketplace](#gm-marketplace)
  - [Table of Contents](#table-of-contents)
  - [Background](#background)
  - [Install](#install)
  - [Foundry Tests](#foundry-tests)

## Background

Consumers are able to purchase and sell tangible things using cryptocurrency on the gm.co marketplace, which makes use of blockchain technology for the purpose of transaction verification and allows users to do so. It functions as a platform for both business-to-consumer (B2C) and peer-to-peer (P2P) transactions. The contracts offer features for buying and selling using ETH and USDC, as well as optional escrow and the signature-based disbursement of funds.

## Deployments

https://gm.co

## Foundry Tests

The GreyMarket contracts contains a test suite written in Forge. To be able to execute and run the tests, please install Foundry by running the following command:

```bash
curl -L https://foundry.paradigm.xyz | bash
```

This will download foundryup. To start Foundry, run:

```bash
foundryup
```

To install dependencies:

```
forge install
```

To run the tests:

```
forge test
```

The following modifiers are also available:

- Level 2 (-vv): Logs emitted during tests are also displayed.
- Level 3 (-vvv): Stack traces for failing tests are also displayed.
- Level 4 (-vvvv): Stack traces for all tests are displayed, and setup traces for failing tests are displayed.
- Level 5 (-vvvvv): Stack traces and setup traces are always displayed.

For more information on foundry testing and use, see [Foundry Book installation instructions](https://book.getfoundry.sh/getting-started/installation.html).

## Audits



## Contributing

Your contribution is highly appreciated and welcomed, whether you want to assist us in reducing gas consumption, increasing test coverage, or have any other ideas that would improve the contracts.

If you'd like to make a contribution such to the GM contracts please ensure:
- All Tests Pass
- Code styling and validation is respected
- You use natspec commenting

###If the contribution is to the contracts:
- Provide documentation of gas improvement.
- Link to any reference material such as contracts or EIPs
- Include new tests, preferably using Foundry, for any new features or code paths.
- Provide a detailed summary of the changes made in the pull request.

## License

[MIT](LICENSE) Copyright 2022 Phantom Network