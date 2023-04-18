// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; //Allows the creation of our ERC20 Token
//import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol"; //Owner can mint and burn
import "@openzeppelin/contracts/access/AccessControl.sol"; //Sets roles
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; //Can Hold ER721 Tokens
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ILendCoin1.sol";
import "./ILendCoin2.sol";
import "./ILendCoin3.sol";
import "./ILendCoin4.sol";

contract LANDmarket is AccessControl {
   bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
   bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
   ILendCoin1 public LendCoin1;
   ILendCoin2 public LendCoin2;
   ILendCoin3 public LendCoin3;
   ILendCoin4 public LendCoin4;

//Global variables
    mapping(address => mapping(uint256 => uint256)) public borrowAccounts; //Track loan accounts
    mapping(address => mapping(uint256 => uint256)) public loanTime; // keeps track of the loan timestamps
    uint256 public BC1 = 3; //Here as integers but they are divided by 10 in the functions
    uint256 public BC2 = 3;
    uint256 public BC3 = 3;
    uint256 public BC4 = 3;
    uint256 public LT1 = 6;
    uint256 public LT2 = 6;
    uint256 public LT3 = 6;
    uint256 public LT4 = 6;
    uint256 public IR1 = 10; //This one is in percentage
    uint256 public IR2 = 10;
    uint256 public IR3 = 10;
    uint256 public IR4 = 10;
    uint256 public discount1 = 9;
    uint256 public discount2 = 9;
    uint256 public discount3 = 9;
    uint256 public discount4 = 9;
    //uint256 public contractValue; //Keeps tracks of the contract pending loans and balance values
    uint256 public contractValue1;
    uint256 public contractValue2;
    uint256 public contractValue3;
    uint256 public contractValue4;
    address public immutable nftContract; //Should be set by the constructor to the NFT contract
    //The following variables are just for the mockup and testing
    mapping(uint256 => uint256) public basketMapping; //keeps track of what basket was the NFT assigned
    //For testing in theory is sent by API
    uint256 public price1 = 100;
    uint256 public price2 = 100;
    uint256 public price3 = 100;
    uint256 public price4 = 100;

//Events necessary for the contract
    event Loan(address indexed _borrower, uint256 _TokenID, uint256 _borrowAmount);
    event Repayment(address indexed _borrower, uint256 _TokenID, uint256 _pendingLoan);
    event Liquidation(address indexed _borrower, uint256 _tokenID);

    constructor(address _nftContract, address _Governor, address _lendCoin1Address, address _lendCoin2Address, address _lendCoin3Address, address _lendCoin4Address) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, address(this)); // minter role probably has to be the contract address and not msg.sender
        _grantRole(ADMIN_ROLE, _Governor); //This could also be a governance contract address
        nftContract = _nftContract; //Sets up address of the NFT in theory it should be decentraland's contracts
        LendCoin1 = ILendCoin1(_lendCoin1Address);
        LendCoin2 = ILendCoin2(_lendCoin2Address);
        LendCoin3 = ILendCoin3(_lendCoin3Address);
        LendCoin4 = ILendCoin4(_lendCoin4Address);
        
    }

//Parameter controls I still think these should be set by the governor of pool and not msg.sender
    function setBC(uint256 _BC, uint256 _basket) external onlyRole(ADMIN_ROLE) {
        require(_basket == 1 || _basket == 2 || _basket == 3 || _basket == 4, "Basket must be 1, 2, 3, or 4");
        if (_basket == 1) {
            BC1 = _BC;
        } else if (_basket == 2) {
            BC2 = _BC;
        } else if (_basket == 3) {
            BC3 = _BC;
        } else {
            BC4 = _BC;
        }
    }
    function setLT(uint256 _LT, uint256 _basket) external onlyRole(ADMIN_ROLE) {
        require(_basket == 1 || _basket == 2 || _basket == 3 || _basket == 4, "Basket must be 1, 2, 3, or 4");
        if (_basket == 1) {
            LT1 = _LT;
        } else if (_basket == 2) {
            LT2 = _LT;
        } else if (_basket == 3) {
            LT3 = _LT;
        } else {
            LT4 = _LT;
        }
    }
    function setIR(uint256 _IR, uint256 _basket) external onlyRole(ADMIN_ROLE) {
        require(_basket == 1 || _basket == 2 || _basket == 3 || _basket == 4, "Basket must be 1, 2, 3, or 4");
        if (_basket == 1) {
            IR1 = _IR;
        } else if (_basket == 2) {
            IR2 = _IR;
        } else if (_basket == 3) {
            IR3 = _IR;
        } else {
            IR4 = _IR;
        }
    }
    function setdiscount(uint256 _discount, uint256 _basket) external onlyRole(ADMIN_ROLE) {
        require(_basket == 1 || _basket == 2 || _basket == 3 || _basket == 4, "Basket must be 1, 2, 3, or 4");
        if (_basket == 1) {
            discount1 = _discount;
        } else if (_basket == 2) {
            discount2 = _discount;
        } else if (_basket == 3) {
            discount3 = _discount;
        } else {
            discount4 = _discount;
        }
    }
    function setPrice(uint256 _price, uint256 _basket) external onlyRole(ADMIN_ROLE) {
        require(_basket == 1 || _basket == 2 || _basket == 3 || _basket == 4, "Basket must be 1, 2, 3, or 4");
        if (_basket == 1) {
            price1 = _price;
        } else if (_basket == 2) {
            price2 = _price;
        } else if (_basket == 3) {
            price3 = _price;
        } else {
            price4 = _price;
        }
    }
    //Changes Admin Role
    function setAdmin(address _newAdmin) external { 
        require(hasRole(ADMIN_ROLE, msg.sender), "Must have admin role");
        require(_newAdmin != address(0), "New admin cannot be zero address");
        revokeRole(ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, _newAdmin);
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
    function fetchPrice(uint256 _tokenID) public returns (uint256 _price) { //Unused parameter is theoretical, it would take the ID and pass it to model API
        uint256 _basket;
        if (basketMapping[_tokenID] == 0) {
            _basket = uint256(keccak256(abi.encodePacked(block.timestamp))) % 4 + 1;
            basketMapping[_tokenID] = _basket;
        } else {
            _basket = basketMapping[_tokenID];
        }
        if (_basket == 1) {
            _price = price1;
        } else if (_basket == 2) {
            _price = price2;
        } else if (_basket == 3) {
            _price = price3;
        } else {
            _price = price4;
        }  
    }

    //Sets variables according to basket
    function setVariablesLiquidation(uint256 _tokenID) internal view returns(uint256 _IR, uint256 _LT, uint256 _discount, uint256 _contractValue) {
    uint256 _basket = basketMapping[_tokenID];
     if (_basket == 1) {
            _IR = IR1;
            _LT = LT1;
            _discount = discount1;
            _contractValue = contractValue1;
        } else if (_basket == 2) {
            _IR = IR2;
            _LT = LT2;
            _discount = discount2;
            _contractValue = contractValue2;
        } else if (_basket == 3) {
            _IR = IR3;
            _LT = LT3;
            _discount = discount3;
            _contractValue = contractValue3;
        } else {
            _IR = IR4;
            _LT = LT4;
            _discount = discount4;
            _contractValue = contractValue4;
        }  
        return (_IR, _LT, _discount, _contractValue);
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
    
    function deposit(uint256 _poolNumber) external payable {
    require(msg.value > 0, "Must deposit some Ether"); // checks that ETH was payed
    if (_poolNumber == 1) {
        if (LendCoin1.totalSupply() == 0) {
        // Mint an initial supply of tokens to the depositor
        uint256 initialSupply = 10;
        LendCoin1.mint(msg.sender, initialSupply);
        // Set the contract value to the initial deposit
        contractValue1 = msg.value;
    } else {
        uint256 share = (msg.value * LendCoin1.totalSupply()) / contractValue1; //Proportionally mints ERC20 tokens
        LendCoin1.mint(msg.sender, share);
        contractValue1 += msg.value;
    }
    } else if (_poolNumber == 2){ 
        if (LendCoin2.totalSupply() == 0) {
        // Mint an initial supply of tokens to the depositor
        uint256 initialSupply = 10;
        LendCoin2.mint(msg.sender, initialSupply);
        // Set the contract value to the initial deposit
        contractValue2 = msg.value;
    } else {
        uint256 share = (msg.value * LendCoin2.totalSupply()) / contractValue2; //Proportionally mints ERC20 tokens
        LendCoin2.mint(msg.sender, share);
        contractValue2 += msg.value;
    }
    } else if (_poolNumber == 3){ 
        if (LendCoin3.totalSupply() == 0) {
        // Mint an initial supply of tokens to the depositor
        uint256 initialSupply = 10;
        LendCoin3.mint(msg.sender, initialSupply);
        // Set the contract value to the initial deposit
        contractValue2 = msg.value;
    } else {
        uint256 share = (msg.value * LendCoin3.totalSupply()) / contractValue3; //Proportionally mints ERC20 tokens
        LendCoin3.mint(msg.sender, share);
        contractValue3 += msg.value;
    }
    } else { 
        if (LendCoin4.totalSupply() == 0) {
        // Mint an initial supply of tokens to the depositor
        uint256 initialSupply = 10;
        LendCoin4.mint(msg.sender, initialSupply);
        // Set the contract value to the initial deposit
        contractValue4 = msg.value;
    } else {
        uint256 share = (msg.value * LendCoin4.totalSupply()) / contractValue4; //Proportionally mints ERC20 tokens
        LendCoin4.mint(msg.sender, share);
        contractValue4 += msg.value;
    }
    }
    }

function withdraw(uint256 _amount, uint256 _poolNumber) external {
    if (_poolNumber == 1) {    
    require(LendCoin1.balanceOf(msg.sender) >= _amount, "Insufficient balance"); //Checks msg.sender has sufficient ERC20 tokens
    uint256 proportionalValue = (_amount * contractValue1) / LendCoin1.totalSupply(); //Calculate proportion of pool 
    contractValue1 -= proportionalValue; //Updates contract value
    require(address(this).balance >= proportionalValue, "The contract does not have the required liquidity"); //In case of loses or too much borrowing
    LendCoin1.transferFrom(msg.sender, address(this), _amount);
    LendCoin1.burn(_amount); //Burns returned tokens
    payable(msg.sender).transfer(proportionalValue); //Transfers ETH
    } else {
    require(LendCoin2.balanceOf(msg.sender) >= _amount, "Insufficient balance"); //Checks msg.sender has sufficient ERC20 tokens
    uint256 proportionalValue = (_amount * contractValue2) / LendCoin2.totalSupply(); //Calculate proportion of pool 
    contractValue2 -= proportionalValue; //Updates contract value
    require(address(this).balance >= proportionalValue, "The contract does not have the required liquidity"); //In case of loses or too much borrowing
    LendCoin2.transferFrom(msg.sender, address(this), _amount);
    LendCoin2.burn(_amount); //Burns returned tokens
    payable(msg.sender).transfer(proportionalValue); //Transfers ETH
    }
}

//Borrow function for NFT Holders
  function borrowLiquidity(uint256 _tokenID, uint256 _borrowAmount) external {
      require(address(this).balance >= _borrowAmount, "The contract does not have the required liquidity");
      address _borrower = msg.sender;
      uint256 _price;
      uint256 _BC;
      uint256 _basket;
      //Calculates price of NFT
     _price = fetchPrice(_tokenID); //function must be defined previously
     _basket = basketMapping[_tokenID];
     if (_basket == 1) {
            _BC = BC1;
        } else if (_basket == 2) {
            _BC = BC2;
        } else if (_basket == 3) {
            _BC = BC3;
        } else {
            _BC = BC4;
        }  

//controls the borrowed amount
      require((_borrowAmount / 1000000000000000000) <= ((_BC * _price)/ 10 ), "Amount to borrow is over the capacity");
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

//Add aditional loan over current one if borrowing capacity allows
  function increaseLoan(address _borrower, uint256 _tokenID, uint256 _borrowAmount) external {
      require(_borrower == msg.sender, "Only the owner of the loan can ask for more liquidity");
      require(address(this).balance >= _borrowAmount, "The contract does not have the required liquidity");
      uint256 _price;
      uint256 _BC;
      uint256 _IR;
      uint256 _basket;
      uint256 _loanValue;
      uint256 _loanTime;
      uint256 _pendingAmount;
      uint256 _accruedInterest;
      uint256 _newBalance;
      uint256 _contractValue;
    
      //Calculates price of NFT
     _price = fetchPrice(_tokenID); //function must be defined previously
     //Check current loan
      _loanValue = checkLoan(_borrower,_tokenID);
      _loanTime = checkTime(_borrower,_tokenID);
      _basket = basketMapping[_tokenID];
     if (_basket == 1) {
            _IR = IR1;
            _contractValue = contractValue1;
        } else if (_basket == 2) {
            _IR = IR2;
            _contractValue = contractValue2;
        } else if (_basket == 3) {
            _IR = IR3;
            _contractValue = contractValue3;
        } else {
            _IR = IR4;
            _contractValue = contractValue4;
        }  
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
//update contract value
     _contractValue = _contractValue + _accruedInterest;
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
      uint256 _basket;
      uint256 _IR;
      uint256 _contractValue;
//Check that ETH has been paid  
      require(msg.value > 0, "No ETH has been payed");
//Check current loan
      _loanValue = checkLoan(_borrower,_tokenID);
      _loanTime = checkTime(_borrower,_tokenID);
      _basket = basketMapping[_tokenID];
     if (_basket == 1) {
            _IR = IR1;
            _contractValue = contractValue1;
        } else if (_basket == 2) {
            _IR = IR2;
            _contractValue = contractValue2;
        } else if (_basket == 3) {
            _IR = IR3;
            _contractValue = contractValue3;
        } else {
            _IR = IR4;
            _contractValue = contractValue4;
        }  
//Calculates accrued interest
      _accruedInterest = calculateAccruedInterest(_loanValue, _loanTime, _IR);
      _pendingAmount = _loanValue + _accruedInterest;
//Updates values or transfer settles loan
if (msg.value < _pendingAmount) {
    _pendingLoan = _pendingAmount - msg.value;
    updateLoanBalance(_borrower, _tokenID, _pendingLoan);
    updateLoanTime(_borrower, _tokenID);
   if (_contractValue == contractValue1) {
        contractValue1 = contractValue1 + _accruedInterest;
    } else if (_contractValue == contractValue2) {
        contractValue2 = contractValue2 + _accruedInterest;
    } 
    else if (_contractValue == contractValue3) {
        contractValue3 = contractValue3 + _accruedInterest;
    } else {
        contractValue4 = contractValue4 + _accruedInterest;
    } 
} else {
    _return = msg.value - _pendingAmount;
    transferETHToSender(_return);
    transferOUTNFT(_borrower, _tokenID);
    updateLoanBalance(_borrower, _tokenID, 0);
    _pendingLoan = 0;
    if (_contractValue == contractValue1) {
        contractValue1 = contractValue1 + _accruedInterest;
    } else if (_contractValue == contractValue2) {
        contractValue2 = contractValue2 + _accruedInterest;
    } else if (_contractValue == contractValue3) {
        contractValue3 = contractValue3 + _accruedInterest;
    } else {
        contractValue4 = contractValue4 + _accruedInterest;
    } 
}
//Update contract value
_contractValue = _contractValue + _accruedInterest;
//emit event
emit Repayment(_borrower, _tokenID, _pendingLoan);
  }

//Liquidation function
  function liquidate(address _borrower, uint256 _tokenID) external payable {
    //loan characteristics
    uint256 _loanValue;
    uint256 _loanTime;
    uint256 _IR;
    uint256 _LT;
    uint256 _discount;
    uint256 _price;
    //calculations
    uint256 _pendingAmount;
    uint256 _return;
    uint256 _discountedPrice;
    uint256 _liquidationValue;
    uint256 _accruedInterest;
    uint256 _contractValue;
//Check that ETH has been paid  
    require(msg.value > 0, "No ETH has been payed");
//Check current loan
      _loanValue = checkLoan(_borrower,_tokenID);
      _loanTime = checkTime(_borrower,_tokenID);
      _price = fetchPrice(_tokenID);
     (_IR, _LT, _discount, _contractValue) = setVariablesLiquidation(_tokenID);
//Calculates accrued interest
     _accruedInterest = calculateAccruedInterest(_loanValue, _loanTime, _IR);
     _pendingAmount = _loanValue + _accruedInterest;
     _liquidationValue = (_price * _LT) * 1000000000000000000 / 10;
//Controls that the NFT can be liquidated
    require(_pendingAmount >= _liquidationValue, "The position is not unhealthy");
//Controls that enough ETH was deposited to buy the NFT
    _discountedPrice = (_price * _discount) / 10 * 1 ether;  
        // Convert the discounted price to Wei
    require(msg.value >= _discountedPrice, "Not enough ETH has been deposited to buy the LAND parcel");
//transfer and settles loan liquidation
    _return = msg.value - _discountedPrice;
    transferETHToSender(_return);
    transferOUTNFT(msg.sender, _tokenID);
    updateLoanBalance(_borrower, _tokenID, 0);
    if (_contractValue == contractValue1) {
        contractValue1 = contractValue1 + _discountedPrice - _loanValue;
    } else if (_contractValue == contractValue2) {
        contractValue2 = contractValue2 + _discountedPrice - _loanValue;
    } else if (_contractValue == contractValue3) {
        contractValue3 = contractValue3 + _accruedInterest;
    } else {
        contractValue4 = contractValue4 + _accruedInterest;
    } 
    //emit event
    emit Liquidation(_borrower, _tokenID);
  }
}