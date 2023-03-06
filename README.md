# claim-soulbound-smart-contract

## Drop Contracts for non-transferable tokens, an extension of Manifold Creator Core Contract

## To Build
forge clean
forge build

## To test
forge test
## To test with logs
forge test -vv

## To deploy to a specific network 
forge create --rpc-url [YOUR-NETWORK-RPC] --constructor-args [ARGS] --private-key [YOUR-WALLET-PRIVATE-KEY] src/ERC1155ClaimTip.sol:ERC1155ClaimTip --etherscan-api-key [YOUR-ETHERSCAN-KEY] --verify