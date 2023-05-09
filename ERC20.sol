// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Used in the `name()` function
bytes32 constant nameLength = 0x0000000000000000000000000000000000000000000000000000000000000009;
bytes32 constant nameData = 0x59756c20546f6b656e0000000000000000000000000000000000000000000000;

// Used in the `symbol()` function
bytes32 constant symbolLength = 0x0000000000000000000000000000000000000000000000000000000000000003;
bytes32 constant symbolData = 0x59554c0000000000000000000000000000000000000000000000000000000000;

// `bytes4(keccak256("InsufficientBalance()"))`
bytes32 constant insufficientBalanceSelector = 0xf4d678b800000000000000000000000000000000000000000000000000000000;

// `bytes4(keccak256("InsufficientAllowance(address,address)"))`
bytes32 constant insufficientAllowanceSelector = 0xf180d8f900000000000000000000000000000000000000000000000000000000;

bytes32 constant transferHash = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;
bytes32 constant approvalHash = 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;
uint256 constant max = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

error InsufficientBalance();
error InsufficientAllowance(address owner, address spender);

/// @title Yul ERC20
/// @author <your name here>
/// @notice For demo purposes ONLY.
contract YulERC20 {
mapping(address => uint256) internal _balances;
mapping(address => mapping(address => uint256)) allowances;
uint256 internal _totalSupply;


event Transfer(address indexed sender, address indexed receiver, uint256 amount);
event Approval(address indexed sender, address indexed receiver, uint256 amount);


constructor() {
    assembly {
        mstore(0x00, caller())
        mstore(0x20, 0x00)
        let hash := keccak256(0x00, 0x40)
        sstore(hash, 10000000000000000000000) //10000 tokens

        sstore(0x02, 10000000000000000000000)

        mstore(0x00,10000000000000000000000)
        log3(0, 0x20, transferHash, 0, caller())

    }
}

function name() public pure returns(string memory){
    assembly {
        let memptr := mload(0x40)
        mstore(memptr, 0x20)
        mstore(add(memptr, 0x20), nameLength)
        mstore(add(memptr, 0x40), nameData)
        return(memptr, 0x60)
}
}

function symbol() public pure returns(string memory){
    assembly {
        let memptr := mload(0x40)
        mstore(memptr, 0x20)
        mstore(add(memptr, 0x20), symbolLength)
        mstore(add(memptr, 0x40), symbolData)
        return(memptr, 0x60)
}

}

function decimals() public pure returns(uint8) {
    assembly {
        mstore(0, 0x12)
        return(0, 32)
    }
}

function totalSupply() public view returns(uint256) {
    assembly {
        mstore(0x00, sload(0x02))
        return(0x00, 0x20)
    }
}

function balanceOf(address account) public view returns(uint256) {
    assembly {
        let addr := account //or calldataload(4)
        mstore(0, addr)
        mstore(0x20, 0)
        let hash := keccak256(0x00, 0x40)

        let bal := sload(hash)
        mstore(0, bal)
        return(0, 0x20)
    }
}

function transfer(address account, uint256 value) public returns(bool) {
    assembly {
        let memptr := mload(0x40)
        mstore(memptr, caller())
        mstore(add(memptr, 0x20) , 0x00)
        let hash := keccak256(memptr, 0x40)
        let bal := sload(hash)

        if lt(bal, value) { 
            mstore(0, insufficientBalanceSelector)
            revert(0, 0x20)
            }

        mstore(0x00, account)
        mstore(0x20, 0x00)
        let hash1 := keccak256(0x00, 0x40)
        let bal1 := sload(hash1)
        let newsenderbal := sub(bal, value)
        let newreceiverbal := add(bal1, value)
        sstore(hash1, newreceiverbal)
        sstore(hash, newsenderbal)

        mstore(0, value)
        log3(0, 0x20, transferHash, caller(), account)

        mstore(0x00, 0x01)
        return(0x00, 0x20)
    }
}
function _allowance(address owner, address spender) public view returns(uint256) {
    assembly {

// keccak256(spender, keccak256(owner, 0x01))
        mstore(0, owner)
        mstore(0x20, 0x01)
        let firstHash := keccak256(0x00, 0x40)

        mstore(0, spender)
        mstore(0x20, firstHash)
        let allowanceSlot := keccak256(0x00, 0x40)
        let allowance := sload(allowanceSlot)
        mstore(0x00, allowance)
        return(0, 0x20)
    }
}

function approve(address spender, uint256 amount) public returns (bool){
    assembly {
        mstore(0, caller())
        mstore(0x20, 0x01)
        let firstHash := keccak256(0x00, 0x40)

        mstore(0, spender)
        mstore(0x20, firstHash)
        let allowanceSlot := keccak256(0x00, 0x40)
        
        sstore(allowanceSlot, amount)
        mstore(0x00, amount)
        log3(0, 0x20, approvalHash, caller(), spender)

        mstore(0, 0x01)
        return(0, 0x20)
    }
}

function transferFrom(address sender, address receiver, uint256 amount) public returns(bool) {
    assembly {

        mstore(0, sender)
        mstore(0x20, 0x01)
        let firstHash := keccak256(0x00, 0x40)

        mstore(0, caller())
        mstore(0x20, firstHash)
        let allowanceSlot := keccak256(0x00, 0x40)
        let allowance := sload(allowanceSlot) 
        

        if lt(allowance, amount) {
            mstore(0, insufficientAllowanceSelector)
            mstore(0x04, sender)
            mstore(0x24, caller())
            revert(0, 0x44)
        }
        
        if lt(allowance, max) {
        sstore(allowanceSlot, sub(allowance, amount))
        }

        mstore(0, sender)
        mstore (0x20, 0x00)
        let hash := keccak256(0, 0x40)
        let senderbal := sload(hash)

        if lt(senderbal, amount) { 
            mstore(0, insufficientBalanceSelector)
            revert(0, 0x20)
        }


        mstore(0x00, receiver)
        mstore(0x20, 0x00)
        let hash1 := keccak256(0x00, 0x40)
        let receiverbal := sload(hash1)
        let newsenderbal := sub(senderbal, amount)
        let newreceiverbal := add(receiverbal, amount)
        sstore(hash1, newreceiverbal)
        sstore(hash, newsenderbal)

        mstore(0, amount)
        log3(0, 0x20, transferHash, sender, receiver)

        mstore(0x00, 0x01)
        return(0x00, 0x20)

}}


}
