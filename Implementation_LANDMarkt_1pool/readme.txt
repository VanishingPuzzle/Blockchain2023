This is the final implementation using 1 POOL, for the 4 pool guide check our repo. The 4 pool implementation has additional functionalities. The one pool implementation is useful for testing, and has b eed deployed and tested in the Sepolia test network.

This is the LAND_MARKT contract deployment guide.

LAND_MARKT is a contract that allows you to deposit NFTs and borrow ETH from a pool using them as collateral.
In this mock-up implementation the prices and loan conditions can be set arbitrarily by the contract ADMIN.

To deploy the contract first deploy the NFT contract called FAKELAND.sol and if you want to use the governor contract deploy the ERC20 governance token decentraLOAN_token.sol
In case you want to use the governor functionality deploy the LAND_MART_governor.sol using the decentraLOAN token as the voting token address.

Now you can deploy LAND_MARKT.sol use the FAKELAND NFT for testing you can set parameters by puting yourself as ADMIN ROLE or put the governor contract as the admin.

NOTE: in this implementation anyone can mint NFTs and set the price for ease of testing.
