// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract MyNFT is ERC721Burnable {
    address public owner;

    // ID count when minting tokens
    uint256 private currentId = 1;
    // storing all minted tokens URI's
    mapping(uint256 => string) private _tokensURI;
    
    constructor() ERC721("soffer", "snft") {
        owner = _msgSender();
    }

    /** @notice Mints 1 nft to `to`
     *  @param to address mints token to
     *  @dev Adding new tokenURI to `_tokensURI` mapping 
     */
    function mint(address to) public virtual {
        require(_msgSender() == owner, "Not an owner!");
        uint256 tokenId = currentId;
        _safeMint(to, tokenId);
        currentId++;
        _tokensURI[tokenId] = tokenURI(tokenId);
    }

    /** @dev Overriden baseURI to new string
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return "google.com/";
    }

    /** @notice get saved tokenURI from mapping by tokenId
     *  @param tokenId ID of the token
     */
    function getNFTLink(uint256 tokenId) public virtual view returns (string memory) {
        _requireOwned(tokenId);
        return _tokensURI[tokenId];
    }
}