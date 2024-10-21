// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract MyNFT is ERC721Burnable {
    address public owner;

    uint256 private currentId = 1;
    mapping(uint256 => string) private _tokensURI;
    
    constructor() ERC721("soffer", "snft") {
        owner = _msgSender();
    }

    function mint(address to) public virtual {
        require(_msgSender() == owner, "Not an owner!");
        uint256 tokenId = currentId;
        _safeMint(to, tokenId);
        currentId++;
        _tokensURI[tokenId] = tokenURI(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "google.com/";
    }

    function getNFTLink(uint256 tokenId) public virtual view returns (string memory) {
        _requireOwned(tokenId);
        return _tokensURI[tokenId];
    }

}