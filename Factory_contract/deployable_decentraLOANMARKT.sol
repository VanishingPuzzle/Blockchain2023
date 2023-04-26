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
    mapping(address => mapping(uint256 => uint256)) public loanIR; // keeps track of a loan interest
    uint256 public immutable BC; //Here as integers but they are divided by 10 in the functions 3
    uint256 public immutable LT; // 7
    uint256 public immutable discount; //9
    uint256 public immutable basket; // 1 to 4
    //uint256 public IR = 10; //This one is in percentage
    //Variable interest rate parameters, They are in basis points to facilitate calculations
    uint256 public immutable slope1;// = 1000;
    uint256 public immutable slope2;// = 6000;
    uint256 public immutable BI; // base interest 500
    uint256 public immutable Uopt; //9000
    uint256 public totalLoans;
    uint256 public contractValue; //Keeps tracks of the contract pending loans and balance values
    address public immutable nftContract; //Should be set by the constructor to the NFT contract
    //The following are just for the mockup and testing
    //For testing in theory is sent by API
    uint256 public price = 3; // in Eth
    mapping(uint256 => uint256) public basketMapping; //keeps track of what basket was the NFT assigned, in reality should be sent by API

//Events necessary for the contract
    event Loan(address indexed _borrower, uint256 _TokenID, uint256 _borrowAmount);
    event Repayment(address indexed _borrower, uint256 _TokenID, uint256 _pendingLoan);
    event Liquidation(address indexed _borrower, uint256 _tokenID);

    constructor(
        address _nftContract, 
        uint256 _BC, 
        uint256 _LT,
        uint256 _basket,
        uint256 _Uopt,
        uint256 _discount,
        uint256 _BI,
        uint256 _slope1,
        uint256 _slope2,
        string memory _name,
        string memory _ticker
    ) ERC20(_name, _ticker) ERC20Permit(_name) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, address(this)); // minter role probably has to be the contract address and not msg.sender
        nftContract = _nftContract; //Sets up address of the NFT in theory it should be decentraland's contracts
        BC = _BC; //Here as integers but they are divided by 10 in the functions 3
        LT = _LT; // 7
        basket = _basket;
        BI = _BI; // base interest 500
        Uopt = _Uopt; //9000
        discount = _discount; //9
        slope1 = _slope1;
        slope2 = _slope2;
    }

    function setPrice(uint256 _price) external {
            price = _price;
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
    //UpdatesIR
    function updateLoanIR(address _borrower, uint256 _tokenID) internal {
        uint256 _IR = setIR(); 
        loanIR[_borrower][_tokenID] = _IR;
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
    function fetchPrice(uint256 _tokenID) public returns (uint256 _price) { //Unused parameter is theoretical, it would take the ID and pass it to model API
        uint256 _basket;
        //If token is new it assigns a basket, if not it check what basket it was
        if (basketMapping[_tokenID] == 0) {
            _basket = uint256(keccak256(abi.encodePacked(block.timestamp))) % 4 + 1;
            basketMapping[_tokenID] = _basket;
        } else {
            _basket = basketMapping[_tokenID];
        }
        _price = price;
    }
    //Variable rate model function
    function setIR() internal view returns(uint256) {
        uint256 _IR;
            uint256 _utilizationRate = (totalLoans * 10000) / contractValue; // calculates utilization
            //if under Uopt slope1 else slope 2
            if (_utilizationRate <= Uopt) {
                _IR = BI + ((_utilizationRate * slope1) / Uopt);
            } else {
                _IR = BI + slope1 + (((_utilizationRate - Uopt) * slope2) / (10000 - Uopt));
            }
            return _IR;
    }   
    
    //Calls the stored value of a specific loan
    function checkLoan(address _borrower, uint256 _tokenID) public view returns (uint256) {
        return borrowAccounts[_borrower][_tokenID];
    }
    //Used to check starting times for interest rate calculations
    function checkTime(address _borrower, uint256 _tokenID) public view returns (uint256) {
        return loanTime[_borrower][_tokenID];
    }
    //Checks IR
     function checkIR(address _borrower, uint256 _tokenID) public view returns (uint256) {
        return loanIR[_borrower][_tokenID];
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
        uint256 decimalApr = _IR * 10**18 / 10000;
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
    require(balanceOf(msg.sender) >= _amount, "Insufficient balance"); //Checks msg.sender has sufficient ERC20 tokens
    uint256 proportionalValue = (_amount * contractValue) / totalSupply(); //Calculate proportion of pool 
     require(address(this).balance >= proportionalValue, "The contract does not have the required liquidity"); //In case of loses or too much borrowing
    contractValue -= proportionalValue; //Updates contract value
    _burn(msg.sender, _amount); //Burns returned tokens
    payable(msg.sender).transfer(proportionalValue); //Transfers ETH
}

//Borrow function for NFT Holders
  function borrowLiquidity(uint256 _tokenID, uint256 _borrowAmount) external {
      require(address(this).balance >= _borrowAmount, "The contract does not have the required liquidity");
      address _borrower = msg.sender;
      uint256 _price;
      uint256 _BC = BC;
      //Calculates price of NFT
     _price = fetchPrice(_tokenID); //function must be defined previously
     require(basketMapping[_tokenID] == basket, "The LAND parcel can not be deposited in this basket");
//controls the borrowed amount
      require((_borrowAmount / 1000000000000000000) <= ((_BC * _price)/ 10 ), "Amount to borrow is over the capacity");
//TransfersNFTs and ETH
      transferINNFT(_tokenID);
      transferETHToSender(_borrowAmount);
//updates the balances
     updateLoanBalance(_borrower, _tokenID, _borrowAmount);
     //Updates IR
     updateLoanIR(_borrower, _tokenID);
//sets loan time
     updateLoanTime(_borrower, _tokenID);
//Updates loan
     totalLoans = totalLoans + _borrowAmount;
//emits Event
      emit Loan(_borrower, _tokenID, _borrowAmount);
  }

//Add aditional loan over current one
  function increaseLoan(address _borrower, uint256 _tokenID, uint256 _borrowAmount) external {
      require(_borrower == msg.sender, "Only the owner of the loan can ask for more liquidity");
      require(address(this).balance >= _borrowAmount, "The contract does not have the required liquidity");
      uint256 _price;
      uint256 _BC = BC;
      uint256 _IR;
      uint256 _loanValue;
      uint256 _loanTime;
      uint256 _pendingAmount;
      uint256 _accruedInterest;
      uint256 _newBalance;
    
      //Calculates price of NFT
     _price = fetchPrice(_tokenID); //function must be defined previously
     //Check current loan
      _loanValue = checkLoan(_borrower,_tokenID);
      _loanTime = checkTime(_borrower,_tokenID);
//Calculates accrued interest
      _accruedInterest = calculateAccruedInterest(_loanValue, _loanTime, _IR);
      _pendingAmount = _loanValue + _accruedInterest;
      _newBalance = _pendingAmount + _borrowAmount;
//controls the borrowed amount
      require((_newBalance / 1000000000000000000) <= ((_BC * _price)/ 10 ), "Amount to borrow is over the capacity");
//TransfersETH
      transferETHToSender(_borrowAmount);
//updates the balances
     updateLoanBalance(_borrower, _tokenID, _newBalance);
//sets loan time
     updateLoanTime(_borrower, _tokenID);
     //updates IR
     updateLoanIR(_borrower, _tokenID);
//update contract value
     contractValue = contractValue + _accruedInterest;
     //Updates loans value
     totalLoans = totalLoans + _borrowAmount + _accruedInterest;
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
      uint256 _IR;
//Check that ETH has been paid  
      require(msg.value > 0, "No ETH has been payed");
//Check current loan
      _loanValue = checkLoan(_borrower,_tokenID);
      _loanTime = checkTime(_borrower,_tokenID);
      _IR = checkIR(_borrower,_tokenID);
//Calculates accrued interest
      _accruedInterest = calculateAccruedInterest(_loanValue, _loanTime, _IR);
      _pendingAmount = _loanValue + _accruedInterest;
//Updates values or transfer settles loan
if (msg.value < _pendingAmount) {
    _pendingLoan = _pendingAmount - msg.value;
    updateLoanBalance(_borrower, _tokenID, _pendingLoan);
    updateLoanTime(_borrower, _tokenID);
    contractValue = contractValue + _accruedInterest;
    totalLoans = totalLoans - msg.value + _accruedInterest;
} else {
    _return = msg.value - _pendingAmount;
    transferETHToSender(_return);
    transferOUTNFT(_borrower, _tokenID);
    updateLoanBalance(_borrower, _tokenID, 0);
    _pendingLoan = 0;
    contractValue = contractValue + _accruedInterest;
        totalLoans = totalLoans - _loanValue;
}
//emit event
emit Repayment(_borrower, _tokenID, _pendingLoan);
  }

//Liquidation function
  function liquidate(address _borrower, uint256 _tokenID) external payable {
    //loan characteristics
    uint256 _loanValue;
    uint256 _loanTime;
    uint256 _IR;
    uint256 _LT = LT;
    uint256 _discount = discount;
    uint256 _price;
    //calculations
    uint256 _pendingAmount;
    uint256 _return;
    uint256 _discountedPrice;
    uint256 _liquidationValue;
    uint256 _accruedInterest;
    
//Check that ETH has been paid  
    require(msg.value > 0, "No ETH has been payed");
//Check current loan
      _loanValue = checkLoan(_borrower,_tokenID);
      _loanTime = checkTime(_borrower,_tokenID);
      _IR = checkIR(_borrower,_tokenID);
      _price = fetchPrice(_tokenID);
//Calculates accrued interest
     _accruedInterest = calculateAccruedInterest(_loanValue, _loanTime, _IR);
     _pendingAmount = _loanValue + _accruedInterest;
     _liquidationValue = (_price * _LT) * 1000000000000000000 / 10;
//Controls that the NFT can be liquidated
    require(_pendingAmount >= _liquidationValue, "The position is not unhealthy");
//Controls that enough ETH was deposited to buy the NFT
    _discountedPrice = ((_price * _discount) * 1 ether) / 10;  
    require(msg.value >= _discountedPrice, "Not enough ETH has been deposited to buy the LAND parcel");
//transfer and settles loan liquidation
    _return = msg.value - _discountedPrice;
    transferETHToSender(_return);
    transferOUTNFT(msg.sender, _tokenID);
    updateLoanBalance(_borrower, _tokenID, 0);
    contractValue = contractValue + _discountedPrice - _loanValue;
    totalLoans = totalLoans - _loanValue;
    //emit event
    emit Liquidation(_borrower, _tokenID);
  }
}
