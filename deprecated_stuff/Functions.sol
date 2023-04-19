pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract LANDmarket is ERC20, ERC20Burnable, AccessControl, ERC20Permit, ERC721 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

//Global variables
    mapping(address => uint256) public depositBalances
    poolValue private uint256 
    circulatingAmount private uint256

    constructor() ERC20("LENDCoin", "LND") ERC20Permit("LANDmarket") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender); // minter role probably has to be the contract address and not msg.sender
    }
//Basic functions
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
    function updateBalance(uint newBalance) public { //This function updates the balance mappings
      depositBalances[msg.sender] = newBalance;
    }

// Deposit function for liquidity providers
    function depositFunds(uint256 amount) public returns(bool success) {
        _depositor public address = msg.sender
        _deposit public uint256 = amount
        _poolProportion internal uint256
        _tokenMintammount internal uint256
    
        transfer(_depositor, _deposit) //takes the deposit in
        updateBalance(_deposit) //Updates the balances global mapping    

        //Calculate pool proportion
        _poolProportion = _deposit/(_deposit + poolValue)
        //Calculate proportion of LENDcoin to issue
        _tokenMintammount = _poolProportion * circulatingAmount / (1 - _poolProportion)
        //mint the calculated amount
        mint(msg.sender, _deposit)
        //Update global variables
        circulatingAmount = circulatingAmount + _tokenMintammount
        poolValue = poolValue + _deposit
    }
}
