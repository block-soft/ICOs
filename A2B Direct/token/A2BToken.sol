pragma solidity ^0.4.11;

import "./SafeMath.sol";

contract A2BToken is SafeMath {
    string public standard = 'ERC20';
    string public name = 'A2B.Token';
    string public symbol = 'A2B';
    uint8 public decimals = 8;

    uint256 constant TOTAL_SUPPLY  = 3000000000000000;

    address public owner;
    modifier onlyOwner {
        if (msg.sender != owner) {
            throw;
        }

        _;
    }

    /* Start tokens transferring timestamp */
    uint256 public startTime = 1499806800; // Tuesday, 11 July 2017, 21:00:00 UTC

    /* All balances */
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

    /* Rewards functionality */
    uint totalReward;
    uint lastDivideRewardTime = startTime;
    struct TokenHolder {
        uint256 balance;
        uint    balanceUpdateTime;
        uint    rewardWithdrawTime;
    }
    mapping(address => TokenHolder) holders;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function A2BToken() {
        owner = msg.sender;

        // Give the owner all initial tokens and init total supply
        balances[owner] = TOTAL_SUPPLY;
    }

    /**
     * Send some of your tokens to a given address
     */
    function transfer(address _to, uint256 _value) returns (bool success) {
        //check if the crowdsale is already over
        if (now < startTime) {
            throw;
        }

        if (balances[msg.sender] < _value || _value <= 0) {
            throw;
        }

        beforeBalanceChanges(msg.sender);
        beforeBalanceChanges(_to);

        balances[msg.sender] = safeSub(balances[msg.sender], _value); // Subtract from the sender
        balances[_to] = safeAdd(balances[_to], _value); // Add the same to the recipient

        Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place

        return true;
    }

    /**
     * A contract or person attempts to get the tokens of somebody else.
     * This is only allowed if the token holder approved.
     */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_from != owner && now < startTime) {
            throw;
        }

        if (balances[_from] < _value || _value <= 0) {
            throw;
        }

        var _allowance = allowance[_from][msg.sender];
        if (_allowance < _value) {
            throw;
        }

        beforeBalanceChanges(_from);
        beforeBalanceChanges(_to);

        balances[_from] = safeSub(balances[_from], _value); // Subtract from the sender
        balances[_to] = safeAdd(balances[_to], _value);     // Add the same to the recipient
        allowance[_from][msg.sender] = safeSub(_allowance, _value);

        Transfer(_from, _to, _value);

        return true;
    }

    /**
     * Allow another contract or person to spend some tokens in your behalf
     */
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }

    function totalSupply() constant returns (uint256 totalSupply) {
        return TOTAL_SUPPLY;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }

    // Rewards distribution part

    function reward() constant public returns(uint) {
        if (holders[msg.sender].rewardWithdrawTime >= lastDivideRewardTime) {
            return 0;
        }

        uint256 balance;
        if (holders[msg.sender].balanceUpdateTime <= lastDivideRewardTime) {
            balance = balances[msg.sender];
        } else {
            balance = holders[msg.sender].balance;
        }

        return totalReward * balance / totalSupply();
    }

    // this can be called by token’s holders
    function withdrawReward() public returns(uint) {
        uint value = reward();
        if (value == 0) {
            return 0;
        }

        if (!msg.sender.send(value)) {
            return 0;
        }

        if (balances[msg.sender] == 0) { // garbage collector
            delete holders[msg.sender];
        } else {
            holders[msg.sender].rewardWithdrawTime = now;
        }

        return value;
    }

    // Divide up reward and make it accessible for withdraw
    function divideUpReward() onlyOwner public {
        // prevent call if less than 30 days passed from previous one
        if (lastDivideRewardTime + 30 days > now) {
            throw;
        }
        lastDivideRewardTime = now;
        totalReward = this.balance;
    }

    function beforeBalanceChanges(address _who) public {
        if (holders[_who].balanceUpdateTime <= lastDivideRewardTime) {
            holders[_who].balanceUpdateTime = now;
            holders[_who].balance = balances[_who];
        }
    }

}
