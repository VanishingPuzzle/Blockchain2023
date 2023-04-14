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
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

//Global variables
    mapping(address => mapping(uint256 => uint256)) public borrowAccounts;
    uint256 public BC = 3; //I put them here as integers but they are divided by 10 in the functions
    uint256 public LT = 6;
    uint256 public IR = 1;
    uint256 public discount = 9;
    uint256 public contractValue;
    address public immutable nftContract = 0xf8e81D47203A594245E36C48e151709F0C19fBe8; //This should be set by the constructor to the NFT contract
    uint256 public price = 100;

//Events
    event Loan(address indexed _borrower, uint256 _TokenID, uint256 _borrowAmount);
    event Repayment(address indexed _borrower, uint256 _TokenID, uint256 _pendingLoan);
    event Liquidation(address indexed _borrower, uint256 _tokenID);

    constructor() ERC20("LENDCoin", "LND") ERC20Permit("LANDmarket") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, address(this)); // minter role probably has to be the contract address and not msg.sender
        _grantRole(ADMIN_ROLE, msg.sender);
    }

//Parameter controls I still think these should be set by the owners of mool and not msg.sender
    function setBC(uint256 _BC) public onlyRole(ADMIN_ROLE) {
       BC = _BC;
    }
    function setLT(uint256 _LT) public onlyRole(ADMIN_ROLE) {
       LT = _LT;
    }
    function setIR(uint256 _IR) public onlyRole(ADMIN_ROLE) {
       IR = _IR;
    }
    function setDiscount(uint256 _discount) public onlyRole(ADMIN_ROLE) {
       discount = _discount;
    }
    function setPrice(uint256 _price) public onlyRole(ADMIN_ROLE) {
       price = _price;
    }
   function setAdmin(address _newAdmin) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Must have admin role");
        require(_newAdmin != address(0), "New admin cannot be zero address");
        revokeRole(ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, _newAdmin);
    }

//Basic functions
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

     function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
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
    function fetchPrice(uint256 _tokenID) internal returns (uint256 _price) {
        _price = price;
    }
    function checkLoan(address _borrower, uint256 _tokenID) public view returns (uint256) {
        return borrowAccounts[_borrower][_tokenID];
    }
    function transferINNFT(uint256 _tokenID) private {
        // Call the safeTransferFrom function of the ERC721 contract
        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), _tokenID);
    }
    function transferOUTNFT(address _target, uint256 _tokenID) private {
        // Call the safeTransferFrom function of the ERC721 contract
        IERC721(nftContract).safeTransferFrom(address(this), _target, _tokenID);
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
    function withdraw(uint256 _amount) external {
    require(address(this).balance >= _amount, "The contract does not have the required liquidity");
    require(balanceOf(msg.sender) >= _amount, "Insufficient balance");
    uint256 proportionalValue = (_amount * contractValue) / totalSupply();
    contractValue -= proportionalValue;
    _burn(msg.sender, _amount);
    payable(msg.sender).transfer(proportionalValue);
}

//Borrow function for NFT Holders
  function borrowLiquidity(uint256 _tokenID, uint256 _borrowAmount) public returns(bool success) {
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
    transferOUTNFT(_borrower, _tokenID);
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
      //Calculates current price of NFT
    _price = fetchPrice(_tokenID); //function must be defined previously
    _liquidationValue = (_price * LT)/10 * 1000000000000000000;
//Controls that the NFT can be liquidated
    require(_pendingAmount >= _liquidationValue, "The position is not unhealthy");
//Controls that enough ETH was deposited to buy the NFT
    _discountedPrice = (_price * discount)/10 * 1000000000000000000;
    require(msg.value >= _discountedPrice, "Not enough ETH has been deposited to buy the LAND parcel");
//transfer and settles loan liquidation
    _return = msg.value - _discountedPrice;
    transferETHToSender(_return);
    transferOUTNFT(msg.sender, _tokenID);
    updateLoanBalance(_borrower, _tokenID, 0);
    contractValue = contractValue + (_discountedPrice - _pendingAmount);
//emit event
    emit Liquidation(_borrower, _tokenID);
  }

}
