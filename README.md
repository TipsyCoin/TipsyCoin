# TipsyCoin

Solidity contracts and Hardhat tests for TipsyCoin.io.

~~Currently, the team is still hard at work testing the contracts before the audit scheduled for the 20th. So some debug and testing code is still present, and small changes to the contracts are likely. Please make sure to grab the latest code on the 20th, and ensure this message has been removed, which indicates a green light. Thanks!~~ Should hopefully be good to go

## Introduction
TipsyCoin is a Safemoon style token with a number of design changes

- First, the token genesis event distributes tokens to a network of auxiliary contracts in order to remove centralisation / privileged account concerns. These contracts either have restrictions on how funds can be used, use multi-sigs for access, or both

- Second, the tax system has been redesigned to only tax sells of TipsyCoin. This is designed to reduce the amount of friction and failed transactions users experience when buying and doing simple transfers

- Third, TipsyCoin features adjustable tax and buyback parameters, which TipsyCoin holders can vote on. These parameters can be individually tweaked, but their combined total may not increase

- Finally, TipsyCoin uses proxy contracts so additional features can be added or bugs fixed, with a multi-sig safeguard

## Design notes
- All tokens minted during genesis. 50% towards LP, 50% towards various other funds, e.g. 10% vested over 12 months for Devolopers. Full tokenomics can be found at: https://tipsycoin.io/tokenomics/

- All contracts listed below (except one, noted in contract list) will be deployed utilizing OpenZeppelin's EIP1967 based TransparentUpgradeableProxy pattern (@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol). Proxies are used so additional features can be added, or bugfixes applied

- To mitigate the risk of centralisation / privileged accounts, the Owner() of the contracts will be set to a GnosisSafe 2 of 3 multi-sig
Further, to mitigate the power of the ProxyAdmin, and to avoid erroneous proxy upgrades, the ProxyAdmin account will be transferred to a 4 of 5 GnosisSafe multi-sig

- In order to reduce friction and failed transactions for buying and simple transfers of the token, only Selling of the token is taxed. This is implemented by hooking the TransferFrom() function that PancakeSwap uses during sells. Whereas Buys on PancakeSwap use the Transfer() function, which does not have a tax applied
The tax has adjustable parameters for percentages towards Community Fund, Reflexive distribution, and the BuyBack fund. It is intended for these parameters to be voted on by Tipsy holders in a DAO style fashion, using Snapshot.org. The parameters, however, cannot be set above a total tax rate set during genesis (10%)

- The max transaction size for non-whitelisted accounts is 0.5% of total supply. Whitelisted accounts are auxiliary accounts such as the Charity or Developer fund
To discourage bots, a noBots modifier is used on all Transfers that checks whether the recipient is a contract. Only whitelisted Contracts (PCS, Developer Fund, etc.) are exempt

- Once Contracts are whitelisted, this permission cannot be revoked, this avoids core contracts (PCS) having their permission accidentally revoked

- To further discourage bots controlling EOA's, during AddLiquidity() a releaseTime variable will be randomly set for ~15 minutes in the future. This time will be announced on our Discord, allowing our users to load up PCS, but standard bots listening for the Liquidity events on PCS will be unable to snipe large amounts of the token

- Finally, whilst a number of variables (views in particular) could be restricted to Private(), the aim of TipsyCoin is to provide as much transparency as can be securely allowed, in aligning with the open nature of crypto.


## Contract list
### TipsyCoin.sol 
The main contract. After Initialization(), at launch, AddLiquidity() is called during Go Time. All LP tokens minted during the AddLiquidity() event are sent to TokenLocker, which locks the LP for 5 years. All additional LP created (for example during Buybacks) is also sent to TokenTimeLock.sol. Only sells are taxed, in the manner described in Design Notes above.

### TokenTimeLock.sol 
Small auxiliary contract that holds the LP tokens minted above. Since this contract is 'single use', it doesn't use a proxy pattern, and is instead deployed directly from TipsyCoin.sol, using Create(). The Benificary() of this contract is set to the address of TipsyCoin.sol, and the LP Release() may be called by anyone. Then, LP may be Salvaged() by the current Owner() of TipsyCoin.sol and redeemed, burned, or locked again.

### TokenVesting.sol
This contract vests the number of TipsyCoin over a 12 month period. This is used for the DeveloperFund. The tokens vested from the contract are send to a seperate TokenDistribution contract, so they can be distributed accordingly. The Release() function by be called by anyone, but is intended to be called Weekly or Monthly

### TokenDistribution.sol
This contract recieves tokens from the TokenVesting.sol. Anyone can call Distribute(), and the contract then distributes tokens to the list of team members according to their weighting score.

### BuyBack.sol
This contract recieves WBNB from the sell tax as described in TipsyCoin allocated to BuyBacks. BuyBacks are used strategically (e.g. weekly). BuyBacks can also be weighted for Reflection, Burn, and AddLiquidity. Reflection buys back TipsyCoin and then distributes it to holders. Burn buys back TipsyCoin and then burns it, reducing max supply. AddLiquidity buys back half TipsyCoin, and then adds liquidity to the pool on PCS. This LP is sent to the same TokenLoker deployed by TipsyCoin, which is locked for 5 years.

### TokenHolder.sol
A very basic contract with a description that can hold and transfer TipsyCoin. Used for segregating the various balances of TipsyCoin, e.g. the 3% Charity fund, and to provide transparency to users. The owner of this will be set to the 2 of 3 GnosisSafe multi-sig to prevent these funds from being misused by a single privelaged account.

## Deploy order
Because Tipsy uses a network of contracts, the order in which they are deployed is important. This is the recommended order for deployment:
1. Deploy a copy of all base contracts: TokenHolder, TokenVesting, TokenDistribution, TipsyCoin, BuyBack
2. Proxy deploy TokenHolder x5 with Initialize(Description). TokenHolders are for the cexFund, charityFund, marketingFund, communityEngagementFund, futureFund
3. Proxy deploy TipsyCoin but don't init
4. Proxy deploy TokenDistribution with Initialize(address TipsyCoin)
5. Proxy deploy TokenVesting with Initialize(address TokenDistribution)
6. Proxy deploy BuyBack, but don't init
7. Proxy Call TipsyCoin Initialize(cexFund, charityFund, marketingFund, communityEngagementFund, futureFund, TokenVesting) function from the proxy. Also creates TimeLock address
8. Proxy Call BuyBack with Initialize(address TipsyCoin, address TokenLocker)

## Hardhat Guide
(todo)

## BSC Testnet Contract Addresses
(todo)

## BSC Mainnet Contract Addresses
(todo)
