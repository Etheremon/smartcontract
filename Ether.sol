// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleEtherWallet {
    address payable public owner;

    // Event that logs deposits
    event Deposit(address indexed sender, uint amount);

    // Event that logs withdrawals
    event Withdrawal(address indexed receiver, uint amount);

    // Constructor sets the owner of the contract
    constructor() {
        owner = payable(msg.sender);
    }

    // Function to deposit Ether into the contract
    function deposit() public payable {
        require(msg.value > 0, "Deposit must be greater than 0");
        emit Deposit(msg.sender, msg.value);
    }

    // Function to withdraw all Ether in the contract, only by the owner
    function withdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw");
        uint balance = address(this).balance;
        require(balance > 0, "Insufficient balance");
        owner.transfer(balance);
        emit Withdrawal(owner, balance);
    }

    // Function to check the balance of the contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
