pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: SimPL-2.0

import "./VerifySignature.sol";
import "./ERC20/IERC20.sol";
import "./ERC721/IERC721TokenReceiverEx.sol";
import "./lib/SafeERC20.sol";
import "./lib/SafeMath.sol";
import "./Package.sol";
import "./Member.sol";

contract SMLMiner is Member, IERC721TokenReceiverEx {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
	
    struct SlotInfo {
        uint256 cardId;
        uint256 level;
        uint256 exp;
    }
    
    event Upgrade(address indexed owner, uint256 indexed cardId, uint256 indexed cardType, uint256 level);
    event RemoveCard(address indexed owner, uint256 indexed cardId);
    event AddToSolt(address indexed owner, uint256 indexed oldCardId, uint256 indexed newCardId);
    
    mapping(address => mapping(uint256 => SlotInfo)) public userSlots;
    uint256 public maxQuantity = 1000;
    
    function setMaxQuantity(uint256 _quantity) external CheckPermit("Config") {
        maxQuantity = _quantity;
    }
    
    function userBuy(bytes memory data) external {
        (address user, uint256 quantity, uint256 amount) = VerifySignature(manager.members("verify")).verifyUserBuy(data);
        require(msg.sender == user, 'invalid user');
        require(quantity <= maxQuantity, 'Exceeded the maximum purchase quantity');
        IERC20(manager.members("token")).safeTransferFrom(msg.sender, manager.members("funder"), amount);
        Package(manager.members("package")).mint(msg.sender, quantity);
    }
    
    function withdraw(bytes memory data) external {
        (address user, uint256 amount) = VerifySignature(manager.members("verify")).verifyWithdraw(data);
        require(msg.sender == user, 'invalid user');
        IERC20(manager.members("token")).safeTransfer(msg.sender, amount);
    }
    
    function getSlotInfo(address owner, uint256 cardType)
        external view returns(SlotInfo memory) {
        return userSlots[owner][cardType];
    }
    
    function onERC721Received(address, address from,
        uint256 cardId, bytes memory data)
        external override returns(bytes4) {
        
        if (msg.sender == manager.members("card")) {
            uint256 operate = uint8(data[0]);
            
            if (operate == 1) {
                uint256[] memory cardIds = new uint256[](1);
                cardIds[0] = cardId;
                _addCards(from, cardIds);
            } else {
                return 0;
            }
        }
        
        return Util.ERC721_RECEIVER_RETURN;
    }
    
    function onERC721ExReceived(address, address from,
        uint256[] memory cardIds, bytes memory data)
        external override returns(bytes4) {
        
        if (msg.sender == manager.members("card")) {
            uint256 operate = uint8(data[0]);
            
            if (operate == 1) {
                _addCards(from, cardIds);
            } else {
                return 0;
            }
        }
        
        return Util.ERC721_RECEIVER_EX_RETURN;
    }
    
    function _addCards(address owner, uint256[] memory cardIds) internal {
        Card card = Card(manager.members("card"));
        for (uint256 i = 0; i < cardIds.length; i++) {
            uint256 cardId = cardIds[i];
            uint256 cardType = uint256(uint64(cardId >> 128));
            
            SlotInfo storage si = userSlots[owner][cardType];
            
            if (si.cardId == 0) {
                si.cardId = cardId;
                emit AddToSolt(owner, 0, cardId);
            } else {
                uint256 oldCardId = si.cardId;
                card.transferFrom(address(this), owner, si.cardId);
                si.cardId = cardId;
                emit AddToSolt(owner, oldCardId, cardId);
            }
        }
    }
    
    function removeCard(uint256 cardType) external {
        SlotInfo storage slot = userSlots[msg.sender][cardType];
        require(slot.cardId > 0, "no card in slot");
        uint256 cardId = slot.cardId;
        slot.cardId = 0;
        Card(manager.members("card")).transferFrom(address(this), msg.sender, cardId);
        emit RemoveCard(msg.sender, cardId);
    }
    
    function removeAllCards() external {
        Card card = Card(manager.members("card"));
        for (uint256 i = 0; i < 52; i++) {
            SlotInfo storage slot = userSlots[msg.sender][i];
            if (slot.cardId > 0) {
                uint256 cardId = slot.cardId;
                slot.cardId = 0;
                card.transferFrom(address(this), msg.sender, cardId);
                emit RemoveCard(msg.sender, cardId);
            }
        }
    }
    
    function upgrade(address owner, uint256[] memory cardIds) external {
        address cardAddr = manager.members("card");
        require(msg.sender == cardAddr, "card only");
        
        for (uint256 i = 0; i < cardIds.length; i++) {
            uint256 cardId = cardIds[i];
            uint256 cardType = uint256(uint64(cardId >> 128));
            
            SlotInfo storage si = userSlots[owner][cardType];
            uint256 cost = getLevelExp(si.level + 1);
            si.exp += 100;
            
            if (si.exp >= cost) {
                si.exp = si.exp.sub(cost);
                si.level = si.level.add(1);
                emit Upgrade(owner, cardId, cardType, si.level);
            }
        }
        
    }
    
    function getLevelExp(uint256 level) private pure returns(uint256) {
        if (level <= 0) {
            return 0;
        }
        if (level == 1) {
            return 100;
        }
        return 200;
    }
    
}
