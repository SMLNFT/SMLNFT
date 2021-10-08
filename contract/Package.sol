pragma solidity ^0.7.0;

// SPDX-License-Identifier: SimPL-2.0

import "./lib/String.sol";
import "./ERC721/ERC721Ex.sol";
import "./Card.sol";
import "./VerifySignature.sol";

contract Package is ERC721Ex {
    using String for string;
    
    uint256 public constant PACKAGE_SIGN_BIT = 1 << 224;
    
    constructor()
        ERC721("SML Package Token", "SMP") {
    }
    
    function mint(address to, uint256 quantity) external {
        require(msg.sender == manager.members("miner"), "not allow");
        
        uint256 packageId = NFT_SIGN_BIT | PACKAGE_SIGN_BIT | (quantity << 128) | 
            (block.timestamp << 64) | (totalSupply + 1);
        
        _mint(to, packageId);
    }
    
    function open(uint256 packageId, bytes memory data) external {
        require(msg.sender == tokenOwners[packageId], "you not own this package");
            
        _burn(packageId);
        (address user, uint256 _packageId, uint256[] memory cardIds) = VerifySignature(manager.members("verify")).verifyOpenPackage(data);
        require(packageId == _packageId, "error package");
        require(msg.sender == user, "error user");
        uint256 quantity = uint256(uint64(packageId >> 128));
        require(quantity == cardIds.length, 'Wrong number of cards');
        
        Card(manager.members("card")).mint(msg.sender, cardIds);
    }
    
    function tokenURI(uint256 packageId)
        external view override returns(string memory) {
        bytes memory bs = abi.encodePacked(packageId);
        return uriPrefix.concat("package/").concat(Util.base64Encode(bs));
    }
}
