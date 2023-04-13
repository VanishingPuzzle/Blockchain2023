//"SPDX license identifier: MIT"
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LANDmarket is ERC20, ERC20Burnable, AccessControl, ERC20Permit {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

//Global variables
    mapping(address => mapping(uint256 => uint256)) public borrowAccounts;
    uint256 public BC = 3; //I put them here as integers but they are divided by 10 in the functions
    uint256 public LT = 6;
    uint256 public IR = 1;
    uint256 public discount = 9;
    uint256 public contractValue;

//Events
    event Loan(address indexed _borrower, uint256 _TokenID, uint256 _borrowAmount);
    event Repayment(address indexed _borrower, uint256 _TokenID, uint256 _pendingLoan);
    event Liquidation(address _borrower, uint256 _tokenID);

    constructor() ERC20("LENDCoin", "LND") ERC20Permit("LANDmarket") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, address(this)); // minter role probably has to be the contract address and not msg.sender
    }
//Basic functions
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
    
    function updateLoanBalance(address _borrower, uint256 _tokenID, uint256 _pendingLoan) internal {
        borrowAccounts[_borrower][_tokenID] = _pendingLoan;
    }
    function transferEth(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Insufficient contract balance");
        recipient.transfer(amount);
    }
    
    function transferETHToSender(uint256 amount) internal {
        transferEth(payable(msg.sender), amount);
    }
    function fetchPrice(uint256 _tokenID) internal returns (uint256 price) {
        price = 100;
    }
    function checkLoan(address _borrower, uint256 _tokenID) public view returns (uint256) {
        return borrowAccounts[_borrower][_tokenID];
    }

// Deposit and withdraw function for liquidity providers
    
    function deposit() external payable {
    require(msg.value > 0, "Must deposit some Ether");
    if (totalSupply() == 0) {
        // Mint an initial supply of tokens to the depositor
        uint256 initialSupply = 10;
        _mint(msg.sender, initialSupply);
        // Set the contract value to the initial deposit
        contractValue = msg.value;
    } else {
        uint256 share = (msg.value * totalSupply()) / contractValue;
        _mint(msg.sender, share);
        contractValue += msg.value;
    }
}
    function withdraw(uint256 amount) external {
    require(balanceOf(msg.sender) >= amount, "Insufficient balance");
    uint256 proportionalValue = (amount * contractValue) / totalSupply();
    contractValue -= proportionalValue;
    _burn(msg.sender, amount);
    payable(msg.sender).transfer(proportionalValue);
}

//Borrow function for NFT Holders
  function borrowLiquidity(uint256 _tokenID, uint256 _borrowAmount) public returns(bool success) {
      address _borrower = msg.sender;
      uint256 _price;
      //Calculates price of NFT
     _price = fetchPrice(_tokenID); //function must be defined previously
      
//controls the borrowed amount
      require(_borrowAmount <= BC / 10 * _price, "Amount to borrow is over the capacity");

//TransfersNFTs and ETH
      transferFrom(msg.sender, address(this), _tokenID); //Should use safe transfer from
      transferETHToSender(_borrowAmount);
//updates the balances
     updateLoanBalance(_borrower, _tokenID, _borrowAmount);
//emits Event
      emit Loan(_borrower, _tokenID, _borrowAmount);
  }

//Pay loans function for NFT holders
  function payLoan(address _borrower, uint256 _tokenID) external payable returns (bool success) {
      uint256 _pendingAmount;
      uint256 _pendingLoan;
      uint256 _return;
//Check that ETH has been paid  
      require(msg.value > 0, "No ETH has been payed");
//Check current loan
      _pendingAmount = checkLoan(_borrower,_tokenID);
//Updates values or transfer settles loan
if (msg.value < _pendingAmount) {
    _pendingLoan = _pendingAmount - msg.value;
    updateLoanBalance(_borrower, _tokenID, _pendingLoan);
} else {
    _return = msg.value - _pendingAmount;
    transferETHToSender(_return);
    transferFrom(address(this), _borrower, _tokenID);
    updateLoanBalance(_borrower, _tokenID, 0);
    _pendingLoan = 0;
}
//emit event
emit Repayment(_borrower, _tokenID, _pendingLoan);
  }

//Liquidation function
  function liquidate(address _borrower, uint256 _tokenID) external payable returns (bool success) {
    uint256 _pendingAmount;
    uint256 _return;
    uint256 _discountedPrice;
    uint256 _price;
    uint256 _liquidationValue;
//Check that ETH has been paid  
    require(msg.value > 0, "No ETH has been payed");
//Check current loan and current price
    _pendingAmount = checkLoan(_borrower,_tokenID); 
      //Calculates price of NFT
    _price = fetchPrice(_tokenID); //function must be defined previously
    _liquidationValue = _price * LT/10;
//Controls that the NFT can be liquidated
    require(_pendingAmount >= _liquidationValue, "The position is not unhealthy");
//Controls that enough ETH was deposited to buy the NFT
    _discountedPrice = _price * discount/10;
    require(msg.value >= _discountedPrice, "Not enough ETH has been deposited to buy the LAND parcel");
//transfer and settles loan liquidation
    _return = msg.value - _discountedPrice;
    transferETHToSender(_return);
    transferFrom(address(this), msg.sender, _tokenID);
    updateLoanBalance(_borrower, _tokenID, 0);
//emit event
    emit Liquidation(_borrower, _tokenID);
  }

}


