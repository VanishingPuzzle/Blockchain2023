This is the LAND_MARKT contract deployment guide.

LAND_MARKT is a contract that allows you to deposit NFTs and borrow ETH from a pool using them as collateral.
In this mock-up implementation the prices and loan conditions can be set arbitrarily by the contract ADMIN. 
This version contains 4 liquidity pools. Each liquidity pool has its own ERC20 contract.

The first step is to deploy all the four LENDCOIN .sol contracts.

Then deploy the NFT contract called FAKELAND.sol. 
In case you want to use the governor functionality deploy the ERC20 governance token decentraLOAN_token.sol and the LAND_MART_governor.sol using the decentraLOAN token as the voting token address.

Now you can deploy LAND_MARKT.sol use the FAKELAND NFT for testing, you can set parameters by puting yourself as ADMIN ROLE or put the governor contract as the admin. Put the LENDCOIN addresses during the deployment and the contract is ready to use!!!
