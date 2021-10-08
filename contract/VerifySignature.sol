pragma solidity ^0.7.0;
// SPDX-License-Identifier: SimPL-2.0

contract VerifySignature {
    
    address private verifyingContract;
    bytes32 private DOMAIN_SEPARATOR;
    address private constant signer = 0x251e2689a0e1b7Bf860131698d9a0dbb22a3c791;
    bytes32 private constant salt = 0x182780e7726be98f1551b492633aad922d74614d4d4fe2c4fc58dac114637de4;
    
    string private constant EIP712_DOMAIN  = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)";
    string private constant PERMIT_USERBUY_TYPE = "PermitUserBuy(address user,uint256 quantity, uint256 amount, uint256 deadLine)";
    string private constant PERMIT_OPEN_TYPE = "PermitOpenPackage(address user,uint256 packageId,uint256[] cardIds, uint256 deadLine)";
    string private constant PERMIT_WITHDRAW_TYPE = "PermitWithdraw(address user,uint256 amount, uint256 deadLine)";

    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));
    bytes32 private constant PERMIT_USERBUY_TYPEHASH = keccak256(abi.encodePacked(PERMIT_USERBUY_TYPE));
    bytes32 private constant PERMIT_OPEN_TYPEHASH = keccak256(abi.encodePacked(PERMIT_OPEN_TYPE));
    bytes32 private constant PERMIT_WITHDRAW_TYPEHASH = keccak256(abi.encodePacked(PERMIT_WITHDRAW_TYPE));
    
    mapping(bytes32 => bool) verifyRecord;
    
    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        verifyingContract = address(this);
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256("SMLShop"),
            keccak256("1.0"),
            chainId,
            verifyingContract,
            salt
        ));
    }
    
    function verifyUserBuy(bytes memory data) 
        external returns(address, uint256, uint256) {
        (address user,uint256 quantity, uint256 amount, uint256 deadLine, bytes memory signature) = abi.decode(data, (address, uint256, uint256, uint256, bytes));
        require(block.timestamp <= deadLine, 'Request Timeout');
        
        bytes32 requestId = keccak256(abi.encode(user,quantity,amount,deadLine));
        require(!verifyRecord[requestId], 'Invalid Data');
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(signature);
        bytes32 signHash = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                PERMIT_USERBUY_TYPEHASH,
                user,
                quantity,
                amount,
                deadLine
            ))
        ));
        require(signer == ecrecover(signHash, v, r, s), 'Invalid Request');
        verifyRecord[requestId] = true;
        return (user, quantity, amount);
    }
    
    function verifyOpenPackage(bytes memory data) 
        external returns(address, uint256, uint256[] memory) {
        (address user,uint256 packageId, uint256[] memory cardIds, uint256 deadLine, bytes memory signature) = abi.decode(data, (address, uint256, uint256[], uint256, bytes));
        require(block.timestamp <= deadLine, 'Request Timeout');
        
        bytes32 requestId = keccak256(abi.encode(user,packageId,cardIds,deadLine));
        require(!verifyRecord[requestId], 'Invalid Data');
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(signature);
        bytes32 signHash = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                PERMIT_OPEN_TYPEHASH,
                user,
                packageId,
                cardIds,
                deadLine
            ))
        ));
        require(signer == ecrecover(signHash, v, r, s), 'Invalid Request!');
        verifyRecord[requestId] = true;
        return (user, packageId, cardIds);
    }
    
    function verifyWithdraw(bytes memory data) 
        external returns(address, uint256) {
        (address user,uint256 amount, uint256 deadLine, bytes memory signature) = abi.decode(data, (address, uint256, uint256, bytes));
        require(block.timestamp <= deadLine, 'Request Timeout');
        
        bytes32 requestId = keccak256(abi.encode(user,amount,deadLine));
        require(!verifyRecord[requestId], 'Invalid Data');
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(signature);
        bytes32 signHash = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                PERMIT_WITHDRAW_TYPEHASH,
                user,
                amount,
                deadLine
            ))
        ));
        require(signer == ecrecover(signHash, v, r, s), 'Invalid Request!');
        verifyRecord[requestId] = true;
        return (user,amount);
    }
    
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65, "Not Invalid Signature Data");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

}
