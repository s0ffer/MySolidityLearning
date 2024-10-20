// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";

interface IERC721Receiver {
    function onERC721Received(
        address operator, 
        address from, 
        uint256 tokenId, 
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    // to transform uint256 to string of `tokenId`
    using Strings for uint256;

    // token name
    string private _name;
    // token symbol
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // includes how much the given address have token's count 
    mapping(address => uint256) private _balances;
    // get owner's address from tokenId
    mapping(uint256 => address) private _owners;
    // check what address approved for work with given token 
    mapping(uint256 => address) private _tokenApprovals;
    // if true operator address can manage of all owner's tokens 
    mapping(address => mapping(address => bool)) private _operatorApprovals;


    /** @notice check for supporting given interface
     *  @param interfaceId given interfaceId to compare support
     *  @return returns true if `interfaceId` equals to supporting interfaces below
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return 
            interfaceId == type(IERC721).interfaceId || 
            interfaceId == type(IERC721Metadata).interfaceId || 
            super.supportsInterface(interfaceId);
    }

    /** @notice get name of the token
     *  @return string of the token name
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /** @notice get symbol of the token
     *  @return string of the symbol name
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /** @notice get URI link of the token
     *  @param tokenId id of the token 
     *  @return path of URI link
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory path) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /** @dev can leave `""` empty if no storage, change to your storage located link
     *  @return base of URI link
     */
    function _baseURI() internal pure returns (string memory base) {
        return "foolink.com/";
    }

    /** @notice get address of the owner of the token
     *  @param tokenId id of the token
     *  @return owner address of the owner
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address owner) {
        require(_owners[tokenId] != address(0), "Incorrect tokenId, doesn't exist");
        return _owners[tokenId];
    }


    /** @notice get balance of how many tokens have the given address
     *  @param owner address of the owner
     *  @return balance number of tokens address own
     */
    function balanceOf(address owner) public view virtual override returns (uint256 balance) {
        require(owner != address(0), "Non-valid address is zero");
        return _balances[owner];
    }


    /** @notice transfer token from `from` to `to`, 
     *  and check `to` if it's a smart contract to check for support IERC721
     *  @param from address of the owner
     *  @param to address transfer token to
     *  @param tokenId id of the token
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /** @notice same as {ERC721-safeTransferFrom} with 3 arguments
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_checkSender(_msgSender(), tokenId), "Caller it's not an owner or approved");
        _transfer(from, to, tokenId);
        require(_checkOnERC721Receiver(from, to, tokenId, data), "Address don't ERC721 Receiver");
    }

    /** @notice transfer token from `from` to `to`
     *  @param from address of the owner
     *  @param to address transfer token to
     *  @param tokenId id of the token
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_checkSender(_msgSender(), tokenId), "Caller it's not an owner or approved");
        _transfer(from, to, tokenId);
    }

    /** @notice get approved address to work with tokenId
     *  @param tokenId id of the token
     *  @return operator address who have approved to work with given tokenId
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address operator) {
         return _tokenApprovals[tokenId];
    }

    /** @notice approve `to` to work with token
     *  @param to address approving for
     *  @param tokenId id of the token
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId); 
        require(_checkSender(_msgSender(), tokenId), "Not approved or not an owner");
        require(to != address(0), "Approve for zero address");
        require(to != owner, "Approve for caller");
        _tokenApprovals[tokenId] = to;

        emit Approval(owner, to, tokenId);
    }

    /** @notice approve `operator` to work with all owner's tokens
     *  @param operator address approving for
     *  @param approved bool flag to set approved or not
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        address owner = _msgSender();
        require(operator != address(0), "Operator is zero address");
        require(owner != operator, "Approve for caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }


    /** @notice check if `operator` approved to work this all owner's tokens
     *  @param owner address of owner
     *  @param operator address of operator
     *  @return bool flag of approved or not
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /** @dev use this variation to ensure safety of minting to `to`
     *  checks `to` for support of IERC721 and other interfaces
     *  @param to address of owner
     *  @param tokenId id of the token
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Receiver(_msgSender(), to, tokenId, ""), 
            "Mint to the Non-ERC721 Receiver"
        );
    }

    /** @dev mints token from zero address and transfers to `to`
     *  @param to address of owner
     *  @param tokenId id of the token
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(!_exists(tokenId), "Token already minted");
        require(to != address(0), "Transfer to the zero address");
        
        unchecked {
            // practically impossible to overflow 
            // unless all 2**256 tokens minted by same owner
            // controlling execution one at a time
            _balances[to] += 1; 
        }

        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    /** @dev burns token to zero address
     *  @param tokenId id of the token
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        delete _tokenApprovals[tokenId];

        unchecked {
            // cannot overflow due owner have at least one token while burning
            _balances[owner] -= 1;
        }

        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }


    /** @dev checks if given token is minted
     *  @param tokenId id of the token
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "Incorrect tokenId, doesn't exist");
    }

    /** @dev compare owner's address of the given token with zero address
     *  @param tokenId id of the token
     *  @return true if token owner's address is not zero address
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }


    /** @dev transfer token from `from` to `to`
     *  @param from address of the owner
     *  @param to address transfer token to
     *  @param tokenId id of the token
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "transfer from the incorrect address");
        require(to != address(0), "transfer to the zero address");

        delete _tokenApprovals[tokenId];

        unchecked {
            // cannot overflow due owner have at least one token on balance
            _balances[from] -= 1;
            // cannot overflow due transfering one token at a time
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }


    /** @dev check if `to ` it's a smart-contract, 
     *  if so check for supporting IERC721Receiver interface
     *  @param from address of the owner
     *  @param to address transfer token to
     *  @param tokenId id of the token
     *  @param data bytes to pass further to function call
     *  @return true if `to` ERC721 Receiver
     */
    function _checkOnERC721Receiver( 
        address from, 
        address to, 
        uint256 tokenId, 
        bytes memory data
    ) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Transfer to Non-ERC721 Receiver");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }


    /** @dev checking sender it's an owner or approved for work with token
     *  @param sender address of the owner
     *  @param tokenId id of the token
     *  @return true if sender allowed to work with the token
     */
    function _checkSender(address sender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (sender == owner || sender == getApproved(tokenId) || isApprovedForAll(owner, sender));  
    }

}

/** @title ERC721Burnable contract implementation 
 */
abstract contract ERC721Burnable is Context, ERC721 {
    
    /** @notice burn token if approved to work with
     *  @param tokenId id of the token
     */
    function burn(uint256 tokenId) public virtual {
        require(_checkSender(_msgSender(), tokenId), "Not an owner or approved");
        _burn(tokenId);        
    }
} 

/** @title creating own token inhereted from ERC721, ERC721Burnable */
contract SofferNFT is ERC721("soffer", "snft"), ERC721Burnable {
    address public owner;
    // increments every mint by 1
    uint256 public currentId = 1;


    constructor() {
        owner = msg.sender;
    }


    /** @dev requires sender is the owner of contract */
    modifier onlyOwner {
        require(msg.sender == owner, "Not the owner of contract");
        _;
    }


    /** @notice mint token to `to` if sender is the owner of contract
     *  @param to address transfer token to
     */
    function mint(address to) public onlyOwner {
        _safeMint(to, currentId);
        currentId += 1;
    }
}