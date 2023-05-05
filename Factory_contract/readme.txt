## Welcome to the factory contract implementation

The deployable_decentraLOANMARKT.sol file contains the same logic as the 1 pool implementation, but it has no setter functions for the parameters.
(except price). 
The parameters are set in its constructor, and they are passed by the deployer contract.

The decentraLOAN_factory.sol contains the deployment function, it passes the arguments to the constructor for the deployable LAND_MARKT.
On the comments in the code you can find the unit format that the parameters take.

Just compile them in the same folder in a remix enviroment and put the factory at work!!!
