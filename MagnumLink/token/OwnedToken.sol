pragma solidity ^0.4.15;

import "./ERC20.sol";

contract OwnedToken is ERC20 {
    address public owner;

    function OwnedToken(){
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

}