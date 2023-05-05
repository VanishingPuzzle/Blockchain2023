# Blockchain2023
EY: Decentraland

**Welcome to the decentraLOAN repositoy**

in this repository you can fin the descriptions for the implementations of the decentraloan protocol.

**Implementation 1 pool**
In the final implemtation 1 pool folder the files for a single pool system are found. These are useful 
for testing purposes, as it ulustrate the logic of all the functions in the contract in a simple to 
deploy and interact system.

You can play with this system directly as it is deployed in the Sepolia testnet!!
Just compile the files in a remix envioment and use contract at address to start testing.
Is open so anyone can mint and change the prices of the baskets for testing. We recomend set price at 3 
and dropping it to 1 for liquidations, as to mantain simple numbers for testing decimals are not implemented for the 
price. Using this numbers the contract can be testing by supplying just 1 SepoliaEth.
Main contract address: 0xa6e460e564b329afaA266D747Ba747562166B56f
NFT contract address: 0x2f9e49ae02E42823D5a68F7650F14853556418Ef

**Implementation 4 pools**
This is our final recomended implementation. Ii has the same logic as the 1 pool system, but it has 4 liquidity pools.
Inside this folder you can find the instructions for deployment.
The logic for all the functions have been tested in a private chain, but is not deployed on the sepolia testnet, as it
is simmpler to test all the logic with the 1 pool implementation.

**Factory contract**
This folder contains a factory contract optional extension. This contract deploys contracts similar to 
the 1 pool contract but with fixed parameters passed by the factory contract. Is an interesting implementation for
testing.

**Pricing models**
This folder contain an example on how the proposed classification algorithm could be implemented. It uses a Kaggle dataset.
It can be expanded with more characteristics for valuation and security features.

**python scripts**
Miscelaneus scripts used for plots and other minor applications in the concept paper, not necessary for grading.
