// // contracts/GameItem.sol
// // SPDX-License-Identifier: BSD-4-Clause
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BIDI is ERC721URIStorage, Ownable {
    address payable public admin;
 
     mapping(uint256 => bool) hashExists;

    constructor() ERC721("BIDI", "BIDI") {
        admin = payable(msg.sender);
    }

    function createToken(string memory _URI, uint256 _hash)
        public
        returns (bool)
    {
        require(msg.sender == admin);
        require(!hashExists[_hash]);
        uint256 _tokenId = _hash;
        _mint(address(this), _tokenId);
        _setTokenURI(_tokenId, _URI);
        
        hashExists[_hash] = true;
        return true;
    }

    // function buy(uint256 _id) external payable {
    //     _validate(_id);
    //     _trade(_id);
    // }

    // function _validate(uint256 _id) internal view {
    //     require(_exists(_id), "Error, wrong Token id");
    //     require(!sold[_id], "Error, Token is sold");
    // }

    // function _trade(uint256 _id) internal {
    //     _transfer(address(this), msg.sender, _id);
    //     admin.transfer(msg.value);
    //     sold[_id] = true;
    // }
}
