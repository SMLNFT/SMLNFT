pragma solidity ^0.7.0;

// SPDX-License-Identifier: SimPL-2.0

import "./ERC20/IERC20.sol";
import "./ERC721/ERC721Ex.sol";
import "./lib/SafeERC20.sol";
import "./lib/String.sol";
import "./lib/Util.sol";

import "./SMLMiner.sol";

contract Card is ERC721Ex {
    using String for string;
	using SafeERC20 for IERC20;
    
    uint256 public constant CARD_SIGN_BIT = 1 << 224;
    
    constructor()
        ERC721("SML Card Token", "SMC") {
    }
    
    function mint(address to, uint256[] memory cardTypes) external {
        require(msg.sender == manager.members("package"), "package only");
        for (uint256 i = 0; i < cardTypes.length; i++) {
            uint256 cardId = NFT_SIGN_BIT | CARD_SIGN_BIT | (cardTypes[i] << 128) | 
                (block.timestamp << 64) | (totalSupply + 1);
            
            _mint(to, cardId);
        }
    }
    
    function burn(uint256 cardId) external {
        address owner = tokenOwners[cardId];
        require(msg.sender == owner
            || msg.sender == tokenApprovals[cardId]
            || approvalForAlls[owner][msg.sender],
            "msg.sender must be owner or approved");
        
        _burn(cardId);
    }
    
    function burnForUpgrade(uint256[] memory cardIds) external {
        address owner = msg.sender;
        for (uint256 i = 0; i < cardIds.length; i++) {
            uint256 cardId = cardIds[i];
            require(owner == tokenOwners[cardId], "you are not owner");
            _burn(cardId);
        }
        
        SMLMiner(manager.members("miner")).upgrade(owner, cardIds);
    }
    
    function tokenURI(uint256 cardId) external view override returns(string memory) {
        bytes memory bs = abi.encodePacked(cardId);
        return uriPrefix.concat("card/").concat(Util.base64Encode(bs));
    }
}
