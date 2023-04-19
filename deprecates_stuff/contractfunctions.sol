// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; //Allows the creation of our ERC20 Token
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol"; //Owner can mint and burn
import "@openzeppelin/contracts/access/AccessControl.sol"; //Sets roles
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; //Can Hold ER721 Tokens
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract LANDmarket is ERC20, ERC20Burnable, AccessControl, ERC20Permit {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

//Global variables
    mapping(address => mapping(uint256 => uint256)) public borrowAccounts; //Track loan accounts
    mapping(address => mapping(uint256 => uint256)) public loanTime; // keeps track of the loan timestamps
    uint256 public BC = 3; //Here as integers but they are divided by 10 in the functions
    uint256 public LT = 6;
    uint256 public IR = 10; //This one is in percentage
    uint256 public discount = 9;
    uint256 public contractValue; //Keeps tracks of the contract pending loans and balance values
    address public immutable nftContract; //Should be set by the constructor to the NFT contract
    uint256 public price = 100; //For testing in theory is sent by API
   

//Events necessary for the contract
    event Loan(address indexed _borrower, uint256 _TokenID, uint256 _borrowAmount);
    event Repayment(address indexed _borrower, uint256 _TokenID, uint256 _pendingLoan);
    event Liquidation(address indexed _borrower, uint256 _tokenID);

    constructor(address _nftContract) ERC20("LENDCoin", "LND") ERC20Permit("LANDmarket") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, address(this)); // minter role probably has to be the contract address and not msg.sender
        _grantRole(ADMIN_ROLE, msg.sender); //This could also be a governance contract address
        nftContract = _nftContract; //Sets up address of the NFT in theory it should be decentraland's contracts

    }

//Parameter controls I still think these should be set by the owners of pool and not msg.sender
    function setBC(uint256 _BC) external onlyRole(ADMIN_ROLE) {
       BC = _BC;
    }
    function setLT(uint256 _LT) external onlyRole(ADMIN_ROLE) {
       LT = _LT;
    }
    function setIR(uint256 _IR) external onlyRole(ADMIN_ROLE) {
       IR = _IR;
    }
    function setDiscount(uint256 _discount) external onlyRole(ADMIN_ROLE) {
       discount = _discount;
    }
    function setPrice(uint256 _price) external onlyRole(ADMIN_ROLE) {
       price = _price;
    }
    //Changes Admin Role
    function setAdmin(address _newAdmin) external { 
        require(hasRole(ADMIN_ROLE, msg.sender), "Must have admin role");
        require(_newAdmin != address(0), "New admin cannot be zero address");
        revokeRole(ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, _newAdmin);
    }

//Basic functions
    function mint(address to, uint256 amount) internal onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
    //Necessary for implementation
     function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
    //Updates mappings for specific loans on borrow, repayment or liquidation
    function updateLoanBalance(address _borrower, uint256 _tokenID, uint256 _pendingLoan) internal {
        borrowAccounts[_borrower][_tokenID] = _pendingLoan;
    }
    function updateLoanTime(address _borrower, uint256 _tokenID) internal {
        loanTime[_borrower][_tokenID] = block.timestamp;
    }
    //We use these to send refunds
    function transferEth(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Insufficient contract balance");
        recipient.transfer(amount);
    }
    
    function transferETHToSender(uint256 amount) internal {
        transferEth(payable(msg.sender), amount);
    }
    //Function that comunicates with external API and gets Price according to basket, here is a constant for testing
    function fetchPrice(uint256 _tokenID) internal view returns (uint256 _price) { //Unused parameter is theoretical, it would take the ID and pass it to model API
        _price = price;
    }
    //Calls the stored value of a specific loan
    function checkLoan(address _borrower, uint256 _tokenID) public view returns (uint256) {
        return borrowAccounts[_borrower][_tokenID];
    }
    //Used to check starting times for interest rate calculations
    function checkTime(address _borrower, uint256 _tokenID) public view returns (uint256) {
        return loanTime[_borrower][_tokenID];
    }
    // We use this function to move in the NFT, it needs to be approved
    function transferINNFT(uint256 _tokenID) internal {
        // Call the safeTransferFrom function of the ERC721 contract
        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), _tokenID);
    }
    // This we use in repayments or liquidations
    function transferOUTNFT(address _target, uint256 _tokenID) internal {
        // Call the safeTransferFrom function of the ERC721 contract
        IERC721(nftContract).safeTransferFrom(address(this), _target, _tokenID);
    }
    //Calculates accrued interest
    function calculateAccruedInterest(uint256 _loanValue, uint256 _loanTime, uint256 _IR) internal view returns (uint256) {
    // Convert APR to a fixed-point decimal value with 18 decimal places
        uint256 decimalApr = _IR * 10**18 / 100;
    // Calculate the time difference in seconds
        uint256 timeDiff = block.timestamp - _loanTime;
    // Calculate the interest rate per second as a fixed-point decimal value
        uint256 interestRatePerSecond = decimalApr / 31536000; // 31536000 is the number of seconds in a year
    // Calculate the accrued interest as a fixed-point decimal value
        uint256 accruedInterest = _loanValue * interestRatePerSecond * timeDiff / 10**18;
        return accruedInterest;
}

// Deposit and withdraw function for liquidity providers
    
    function deposit() external payable {
    require(msg.value > 0, "Must deposit some Ether"); // checks that ETH was payed
    if (totalSupply() == 0) {
        // Mint an initial supply of tokens to the depositor
        uint256 initialSupply = 10;
        _mint(msg.sender, initialSupply);
        // Set the contract value to the initial deposit
        contractValue = msg.value;
    } else {
        uint256 share = (msg.value * totalSupply()) / contractValue; //Proportionally mints ERC20 tokens
        _mint(msg.sender, share);
        contractValue += msg.value;
    }
}
    function withdraw(uint256 _amount) external {
    require(address(this).balance >= _amount, "The contract does not have the required liquidity"); //In case of loses or too much borrowing
    require(balanceOf(msg.sender) >= _amount, "Insufficient balance"); //Checks msg.sender has sufficient ERC20 tokens
    uint256 proportionalValue = (_amount * contractValue) / totalSupply(); //Calculate proportion of pool 
    contractValue -= proportionalValue; //Updates contract value
    _burn(msg.sender, _amount); //Burns returned tokens
    payable(msg.sender).transfer(proportionalValue); //Transfers ETH
}

//Borrow function for NFT Holders
  function borrowLiquidity(uint256 _tokenID, uint256 _borrowAmount) external {
      require(address(this).balance >= _borrowAmount, "The contract does not have the required liquidity");
      address _borrower = msg.sender;
      uint256 _price;
      //Calculates price of NFT
     _price = fetchPrice(_tokenID); //function must be defined previously
//controls the borrowed amount
      require((_borrowAmount / 1000000000000000000) <= ((BC * _price)/ 10 ), "Amount to borrow is over the capacity");
//TransfersNFTs and ETH
      transferINNFT(_tokenID);
      transferETHToSender(_borrowAmount);
//updates the balances
     updateLoanBalance(_borrower, _tokenID, _borrowAmount);
//sets loan time
     updateLoanTime(_borrower, _tokenID);
//emits Event
      emit Loan(_borrower, _tokenID, _borrowAmount);
  }

//Pay loans function for NFT holders
  function payLoan(address _borrower, uint256 _tokenID) external payable {
      uint256 _loanValue;
      uint256 _pendingAmount;
      uint256 _accruedInterest;
      uint256 _pendingLoan;
      uint256 _return;
      uint256 _loanTime;
//Check that ETH has been paid  
      require(msg.value > 0, "No ETH has been payed");
//Check current loan
      _loanValue = checkLoan(_borrower,_tokenID);
      _loanTime = checkTime(_borrower,_tokenID);
//Calculates accrued interest
      _accruedInterest = calculateAccruedInterest(_loanValue, _loanTime, IR);
      _pendingAmount = _loanValue + _accruedInterest;
//Updates values or transfer settles loan
if (msg.value < _pendingAmount) {
    _pendingLoan = _pendingAmount - msg.value;
    updateLoanBalance(_borrower, _tokenID, _pendingLoan);
    updateLoanTime(_borrower, _tokenID);
} else {
    _return = msg.value - _pendingAmount;
    transferETHToSender(_return);
    transferOUTNFT(_borrower, _tokenID);
    updateLoanBalance(_borrower, _tokenID, 0);
    _pendingLoan = 0;
}
//Update contract value
contractValue = contractValue + _accruedInterest;
//emit event
emit Repayment(_borrower, _tokenID, _pendingLoan);
  }

//Liquidation function
  function liquidate(address _borrower, uint256 _tokenID) external payable {
    uint256 _loanValue;
    uint256 _loanTime;
    uint256 _pendingAmount;
    uint256 _return;
    uint256 _discountedPrice;
    uint256 _discountedPriceInWei;
    uint256 _price;
    uint256 _liquidationValue;
    uint256 _accruedInterest;
//Check that ETH has been paid  
    require(msg.value > 0, "No ETH has been payed");
//Check current loan
      _loanValue = checkLoan(_borrower,_tokenID);
      _loanTime = checkTime(_borrower,_tokenID);
      _price = fetchPrice(_tokenID);
//Calculates accrued interest
     _accruedInterest = calculateAccruedInterest(_loanValue, _loanTime, IR);
     _pendingAmount = _loanValue + _accruedInterest;
     _liquidationValue = (_price * LT) * 1000000000000000000 / 10;
//Controls that the NFT can be liquidated
    require(_pendingAmount >= _liquidationValue, "The position is not unhealthy");
//Controls that enough ETH was deposited to buy the NFT
    _discountedPrice = (_price * discount) / 10;  
        // Convert the discounted price to Wei
    _discountedPriceInWei = _discountedPrice * 1 ether;
    require(msg.value >= _discountedPriceInWei, "Not enough ETH has been deposited to buy the LAND parcel");
//transfer and settles loan liquidation
    _return = msg.value - _discountedPriceInWei;
    transferETHToSender(_return);
    transferOUTNFT(msg.sender, _tokenID);
    updateLoanBalance(_borrower, _tokenID, 0);
    contractValue = contractValue + _discountedPriceInWei - _loanValue;
    //emit event
    emit Liquidation(_borrower, _tokenID);
  }
}
