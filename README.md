# TipsyCoin

Solidity contracts and Hardhat tests for TipsyCoin.io.

## Introduction
TipsyCoin is a Safemoon style token with a number of design changes

- First, the token genesis event distributes tokens to a network of auxiliary contracts in order to reduce centralisation / privileged account concerns. These contracts either have restrictions on how funds can be used, use multi-sigs for access, or both. In addition, following suggestions from CertiK, a timelock delay of 48 has also been utilised to further mitigate centralisation / privileged account concerns  

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

### TimelockController.sol
A governance timelock contract from OpenZepplin. This is used to reduce centralisation concerns noted by CertiK in their audit of TipsyCoin. In order to do this, all contracts with centralisation concerns will have their Owner() set to the governance timelock contract, which will enforce a 48 hour delay in execution. Two TimelockControllers will be used for the deployment (one for ProxyAdmin, one for Owner), both with a 48 hour delay. The Proposers for these TimelockController's will be The 3/5 Gnosis Multisig for ProxyAdmin, and the 2/3 Gnosis Multisig for the Owner. The Executors for these TimelockControllers will be the members of those respective Multisigs, plus the TipsyCoin Deployment wallet. Deployment diagram which includes the TimelockController can be found below

## Deploy order
Because Tipsy uses a network of contracts, the order in which they are deployed is important. This is the recommended order for deployment:
0. Deploy 2x copies of TimelockController.sol with a minimum delay of 48 hours, and set the proposers to the GnosisSafe multisig wallets (2/3 for Owner(), and 3/5 for ProxyAdmin(). Set the executors to the same set plus the Deployment wallet and note the TimelockController addresses. 
1. Deploy a copy of all base contracts: TokenHolder, TokenVesting, TokenDistribution, TipsyCoin, BuyBack
2. Proxy deploy TokenHolder x5 with Initialize(Description). TokenHolders are for the cexFund, charityFund, marketingFund, communityEngagementFund, futureFund
3. Proxy deploy TipsyCoin but don't init
4. Init TokenDistribution with Initialize(address TipsyCoin)
5. Init TokenVesting with Initialize(address TokenDistribution, start now, duration 31536000)
6. Proxy deploy BuyBack, but don't init
7. Proxy Call TipsyCoin Initialize(cexFund, charityFund, marketingFund, communityEngagementFund, futureFund, TokenVesting) function from the proxy. Also creates TimeLock address
8. Proxy Call BuyBack with Initialize(address TipsyCoin, address TokenLocker)
9. Finally, once all contracts have been deployed and configured, set their owners to the TimelockController addresses noted above

The final deployment should look like this:
![TipsyDiag3](https://user-images.githubusercontent.com/97759975/153759674-8a918335-2706-44db-bd3d-4e4fdbdd7c69.png)

## Hardhat Guide


Follow : https://hardhat.org/getting-started/ if not already set up with Hardhat

`npm install`
`npx hardhat test`

After this you should be able to see all the passing tests for TokenVesting, Timelock, and Distribution.

## BSC Testnet Contract Addresses
(todo)

## BSC Mainnet Contract Addresses
GnosisSafe #1 -> (still yet to fully setup, will be 2 of 3) -> bnb:0x884C908ea193B0Bb39f6A03D8f61C938F862e153

GnosisSafe #2 -> (still yet to full setup, will be 3 of 5) -> bnb:0xb4620C524245c584C5C2Ba79FD20CeB926FBd418

(todo)
