pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: SimPL-2.0

import "./Member.sol";
import "./ERC20/IERC20.sol";
import "./ERC721/IERC721.sol";
import "./lib/SafeMath.sol";
import "./lib/SafeERC20.sol";

contract SMLExchange is Member {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    event CreateOrder(address indexed maker, uint256 indexed tokenid, uint256 payAmount);
    event TradeOrder(uint256 indexed tokenid, address maker, address taker, bytes32 orderid);
    event CancelOrder(uint256 indexed tokenid);
    
    struct ExchangeOrder {
        address     maker;
        address     taker;
        uint256     cardid;
        uint256     payAmount;
        uint256     createTime;
        uint256     tradeTime;
    }
    
    mapping(uint256 => ExchangeOrder) private makerOrders;
    mapping(bytes32 => ExchangeOrder) private tradeOrders;
    uint256 private constant fees = 5;
    
    function createOrder(uint256 tokenid, uint256 tradeAmount) external {
        require(makerOrders[tokenid].maker == address(0), "Exists Order!");
        
        IERC721(manager.members("card")).transferFrom(msg.sender, address(this), tokenid);
        makerOrders[tokenid].maker = msg.sender;
        makerOrders[tokenid].cardid = tokenid;
        makerOrders[tokenid].payAmount = tradeAmount;
        makerOrders[tokenid].createTime = block.timestamp;
        emit CreateOrder(msg.sender, tokenid, tradeAmount);
    }
    
    function takeOrder(uint256 tokenid) external {
        ExchangeOrder memory order = makerOrders[tokenid];
        require(order.maker != address(0), "Not Exists Order!");
        
        uint256 payAmount = order.payAmount;
        uint256 tradeFees = payAmount.mul(fees).div(1000);
        uint256 sendAmount = payAmount.sub(tradeFees);
        IERC20(manager.members("token")).safeTransferFrom(msg.sender, manager.members("funder"), tradeFees);
        IERC20(manager.members("token")).safeTransferFrom(msg.sender, order.maker, sendAmount);
        
        IERC721(manager.members("card")).transferFrom(address(this), msg.sender, tokenid);
        
        order.taker = msg.sender;
        order.tradeTime = block.timestamp;
        bytes32 orderid = keccak256(abi.encode(
            tokenid,
            order.maker,
            order.taker,
            block.number
        ));
        
        delete makerOrders[tokenid];
        tradeOrders[orderid] = order;
        emit TradeOrder(tokenid, order.maker, msg.sender, orderid);
    }
    
    function cancelOrder(uint256 tokenid) external {
        ExchangeOrder memory order = makerOrders[tokenid];
        require(order.maker == msg.sender, "invalid card");
        IERC721(manager.members("card")).transferFrom(address(this), msg.sender, tokenid);
        delete makerOrders[tokenid];
        emit CancelOrder(tokenid);
    }
    
    function getMakerOrder(uint256 tokenid) external view returns(ExchangeOrder memory) {
        return makerOrders[tokenid];
    }
    
    function getTradeOrder(bytes32 tokenid) external view returns(ExchangeOrder memory) {
        return tradeOrders[tokenid];
    }
}
