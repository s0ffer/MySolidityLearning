// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/// @dev interface of IERC20 already imported in SafeERC20 file.
// interface IERC20 {
//     function name() external view returns(string memory);
//     function symbol() external view returns(string memory);
//     function decimals() external view returns(uint8);
//     function totalSupply() external view returns(uint256);
//     function balanceOf(address _owner) external view returns(uint256 balance);
//     function transfer(address _to, uint256 _value) external returns(bool success);
//     function transferFrom(address _from, address _to, uint256 _value) external returns(bool success);
//     function approve(address _spender, uint256 _value) external returns(bool success);
//     function allowance(address _owner, address _spender) external view returns(uint256 remaining);
//     event Transfer(address indexed _from, address indexed _to, uint256 _value);
//     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
// }

/// @title base contract ERC20 
/// @author s0ffer
/// @notice my implementation of ERC20
/// @dev my practice in implementation of ERC20 standart
abstract contract ERC20 is IERC20 {

    using SafeMath for uint256;
    
    constructor(address owner_, string memory name_, string memory symbol_, uint8 decimals_) {
        owner = owner_;
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }
    
    address private owner;

    mapping(address owner => uint256) private _balances;
    mapping(address owner => mapping(address spender => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private _totalSupply;

    modifier onlyOwner {
        require(msg.sender == owner, "You aren't an owner!");
        _;
    }

    /// @notice Returns the name of the token.
    /// @dev Name stored in `_name`
    /// @return string of the token name. 
    function name() public view returns(string memory) {
        return _name;
    }

    /// @notice Returns the symbol of the token.
    /// @dev Symbol stored in `_symbol`
    /// @return string of the token symbol. 
    function symbol() public view returns(string memory) {
        return _symbol;
    }

    /// @notice Returns the decimals of the token.
    /// @dev Decimals stored in `_decimals`
    /// @return uint8 of the token decimals. 
    function decimals() public view returns(uint8) {
        return _decimals;
    }

    /// @notice Returns the total supply of the token.
    /// @dev Total supply stored in `_totalSupply`
    /// @return uint256 of the token total supply. 
    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    /// @notice Returns the balance of account.
    /// @dev Balances stored in `_balances` mapping by key: address
    /// @param _owner address of whose balance to see.
    /// @return balance uint256 balance of account.  
    function balanceOf(address _owner) public view returns(uint256 balance) {
        return _balances[_owner];
    }

    /// @notice Transfers `_value` amount tokens to `_to`.
    /// @dev Require `_value` greater than balance of the sender.
    /// @param _to address to transfer tokens.
    /// @param _value amount of token to transfer.
    /// @return success boolean. 
    function transfer(address _to, uint256 _value) external returns(bool success) {
        require(_balances[msg.sender] >= _value, "Insufficient balance of sender");
        _update(msg.sender, _to, _value);
        return true;
    }

    /// @notice Transfers `_value` amount tokens from `_from` to `_to`.
    /// @dev Require left allowance greater than `_value` and `_value` greater than balance of the sender
    /// @param _from address transfering tokens from.
    /// @param _to address to transfer tokens.
    /// @param _value amount of token to transfer.
    /// @return success boolean. 
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool success) {
        require(_allowances[_from][msg.sender] >= _value, "Insufficient allowance for this account");
        require(_balances[_from] >= _value, "Insufficient balance of account for transferFrom");
        _allowances[_from][msg.sender] -= _value;
        _update(_from, _to, _value);
        return true;
    }

    /// @notice Approve to spend some amount of tokens to the spender.
    /// @dev checking current allowance of spender, decreases or increases allowance if greater or smaller. Emits event `Approval`.
    /// @param _spender address to who approve spend tokens.
    /// @param _value amount of token to approve.
    /// @return success boolean.
    function approve(address _spender, uint256 _value) public returns(bool success) {
        uint256 currentAllowance = _allowances[msg.sender][_spender];
        require(_spender != address(0), "InvalidSpender");
        require(msg.sender != address(0), "InvalidApprover");
        if (currentAllowance > _value) {
            (, uint256 newValue) = currentAllowance.trySub(_value);
            _allowances[msg.sender][_spender] = newValue;
        }
        if (currentAllowance < _value) {
            (, uint256 newValue) = currentAllowance.tryAdd(_value);
            _allowances[msg.sender][_spender] = newValue;
        } else {
            require(currentAllowance == _value, "Equals to the current allowance");
        }
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @notice Returns left allowance for spender from owners account.
    /// @dev allowance stored in `_allowances` mapping by key: address => address.
    /// @param _owner address of account.
    /// @param _spender address who got allowance.
    /// @return remaining uint256 allowance left.
    function allowance(address _owner, address _spender) public view returns(uint256 remaining) {
        return _allowances[_owner][_spender];
    }

    /// @notice Updates balances.
    /// @dev if `_from` zero address -> mint, if `to` zero address -> burn. Emits event `Transfer`.
    /// @param _from address tokens transfer from.
    /// @param _to address tokens transfer to.
    /// @param _value amount of tokens to transfer.
    function _update(address _from, address _to, uint256 _value) internal virtual {
        if (_from == address(0)) {
            _totalSupply += _value;
        } else {
            _balances[_from] -= _value;
        }
        if (_to == address(0)) {
            _totalSupply -= _value;
        } else {
            _balances[_to] += _value;
        }
        emit Transfer(_from, _to, _value);
    }

    /// @notice Create tokens.
    /// @dev Sets `from` to zero address in update args for mint. Function only for owner.
    /// @param to address tokens transfer to.
    /// @param value amount of tokens to mint.
    /// @return success boolean.
    function mint(address to, uint256 value) public onlyOwner returns(bool success) {
        require(to != address(0));
        _update(address(0), to, value);
        return true;
    }

    /// @notice Remove tokens.
    /// @dev Sets `to` to zero address in update args for burn. Function only for owner.
    /// @param from address tokens transfer from.
    /// @param value amount of tokens to burn.
    /// @return success boolean.
    function burn(address from, uint256 value) public onlyOwner returns(bool success) {
        require(from != address(0));
        _update(from, address(0), value);
        return true;
    }

}

/// @title contract of the first token "CUSD" 
/// @author s0ffer
/// @notice create token inheritated from ERC20
/// @dev decimals 6, similar to USDT, USDC tokens
contract CUSD is ERC20 {

    /// Uses contructor for initiate ERC20 constructor to set variables.
    /// @dev Decimals set to 6
    /// @param initialOwner address of the token owner. 
    constructor(address initialOwner) ERC20(initialOwner, "Coin USD", "CUSD", 6) {}
}

/// @title contract of the second token "COIN" 
/// @author s0ffer
/// @notice create token inheritated from ERC20
/// @dev decimals 18, similar to native ETH token
contract COIN is ERC20 {

    /// Uses contructor for initiate ERC20 constructor to set variables.
    /// @dev Decimals set to 18
    /// @param initialOwner address of the token owner. 
    constructor(address initialOwner) ERC20(initialOwner, "Coin native", "COIN", 18) {}
}

/// @title contract of potato dex
/// @author s0ffer
/// @notice function of buying token and swapping.
/// @dev for proper work address of `buy` this contract must have balances in both tokens. 
/// @dev for `swap` user must approve balance to this contract
contract TokenSwap {
    using SafeERC20 for IERC20;

    address payable public owner;

    IERC20 cusdToken;
    IERC20 coinToken;

    event Swap(address indexed from, uint256 amountIn, uint256 amountOut);

    constructor(address _CUSD, address _COIN, address _owner) {
        cusdToken = IERC20(_CUSD);
        coinToken = IERC20(_COIN);
        owner = payable(_owner);
    }

    /// Consumes ETH, transfers equal amount of the token, 1 wei == 1 token. 
    /// @dev This contract needs to have that amount of tokens. Mint them. Compares `tokenAddress` to CUSD and COIN token addresses.
    /// @param tokenAddress address of the token.
    /// @return success boolean. 
    function buy(address tokenAddress) public payable returns(bool success) {
        if (tokenAddress == address(cusdToken)) {
            require(cusdToken.balanceOf(address(this)) > msg.value, "Insufficient balance in contract");
            cusdToken.safeTransfer(msg.sender, (msg.value / (10 ** 12)));
        } else if (tokenAddress == address(coinToken)) {
            require(coinToken.balanceOf(address(this)) > msg.value, "Insufficient balance in contract");
            coinToken.safeTransfer(msg.sender, msg.value);
        } else {
            revert("Invalid token address");
        }
        return true;
    }

    /// Consume tokenA amount of a tokens, transfers equal tokenB amount to the sender.
    /// @dev Compares `tokenA` address to CUSD and COIN token addresses. Emits `Swap` event.
    /// @param tokenA address of the input token.
    /// @param amountA uint256 input amount swap for.
    /// @return success boolean. 
    function swap(address tokenA, uint256 amountA) public returns(bool success) {
        bool isCusdToken = tokenA == address(cusdToken);
        
        isCusdToken 
            ? cusdToken.safeTransferFrom(msg.sender, address(this), amountA) 
            : coinToken.safeTransferFrom(msg.sender, address(this), amountA);

        uint256 amountB = isCusdToken 
            ? amountA * (10 ** 12) 
            : amountA / (10 ** 12);

        isCusdToken 
            ? cusdToken.safeTransfer(msg.sender, amountB) 
            : coinToken.safeTransfer(msg.sender, amountB);

        emit Swap(msg.sender, amountA, amountB);
        return true;
    }


    /// Withdraw all eth from the contract to the owner account.
    /// @dev Require the contract balance greater than zero.
    function withdrawAll() public {
        require(msg.sender == owner, "Not the contract owner!");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        owner.transfer(balance);
    }
}