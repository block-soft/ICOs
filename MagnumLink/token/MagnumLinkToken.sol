pragma solidity ^0.4.15;

import "./SafeMath.sol";
import "./OwnedToken.sol";

contract MagnumLinkToken is SafeMath, OwnedToken {
    string public standard = 'ERC20';
    string public name = 'MagnumLinkToken';
    string public symbol = 'MLT';
    uint8 public decimals = 8;

    uint public totalTokensSupply = 100000000000000000; // Total tokens supply

    /* Start tokens transferring timestamp */
    uint public startTime = 1506816000; // 2017-10-01T00:00:00+00:00
    bool private burned = false;

    /* All balances */
    mapping (address => uint) public balances;
    mapping (address => mapping (address => uint)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Burned(uint _amount);

    function MagnumLinkToken() {
        owner = msg.sender;

        // Give the owner all initial tokens and init total supply
        balances[owner] = totalTokensSupply;
    }

    /**
     * Send some of your tokens to a given address
     */
    function transfer(address _to, uint _value) returns (bool success) {
        //check if the crowdsale is already over
        require(now >= startTime);

        require(balances[msg.sender] >= _value && _value > 0);

        balances[msg.sender] = safeSub(balances[msg.sender], _value); // Subtract from the sender
        balances[_to] = safeAdd(balances[_to], _value); // Add the same to the recipient

        Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place

        return true;
    }

    /**
     * A contract or person attempts to get the tokens of somebody else.
     * This is only allowed if the token holder approved.
     */
    function transferFrom(address _from, address _to, uint _value) returns (bool success) {
        require(now >= startTime);

        require(balances[_from] >= _value && _value > 0);

        var _allowance = allowance[_from][msg.sender];
        require(_allowance >= _value);

        balances[_from] = safeSub(balances[_from], _value); // Subtract from the sender
        balances[_to] = safeAdd(balances[_to], _value);     // Add the same to the recipient
        allowance[_from][msg.sender] = safeSub(_allowance, _value);

        Transfer(_from, _to, _value);

        return true;
    }

    /**
     * Allow another contract or person to spend some tokens in your behalf
     */
    function approve(address _spender, uint _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }

    function totalSupply() constant returns (uint totalSupply) {
        return totalTokensSupply;
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowance[_owner][_spender];
    }

    // Tokens burning
    function burn(uint _amount) onlyOwner {
        require(now < startTime && !burned);
        require(_amount > 0);
        require(totalTokensSupply >= _amount && balances[owner] >= _amount);

        totalTokensSupply = safeSub(totalTokensSupply, _amount);
        balances[owner] = safeSub(balances[owner], _amount);

        burned = true;
        Burned(_amount);
    }

}
