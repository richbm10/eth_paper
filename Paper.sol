// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.26;

contract Paper {
    mapping (address => uint256) public balance;
    address public owner;
    uint256 public limit;
    uint256 public circulation;
    string public name;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");

        _;
    }

    modifier belowMintedLimit(uint256 _amount) {
        uint256 increasedCirculation = circulation + _amount;
        require(increasedCirculation <= limit, "Amount can not be minted as it exceeds the token circulation limit!");

         _;
    }

    modifier enoughBalance(address _address, uint256 _amount) {
        require(_amount <= balance[_address], "Insufficient balance!");

        _;
    }

    constructor(string memory _name, uint256 _limit, uint _initialTreasuryPercentage) {
        owner = msg.sender;
        name = _name;
        limit = _limit;
        uint bps = _initialTreasuryPercentage * 100;
        uint initialTreasury = _limit * bps / 10_000;
        mint(msg.sender, initialTreasury);
    }

    function mint(address _wallet, uint256 _amount) public onlyOwner belowMintedLimit(_amount) {
        balance[_wallet] = balance[_wallet] + _amount;
        circulation = circulation + _amount;
    }

    function transfer(address _to, uint256 _amount) public enoughBalance(msg.sender, _amount) {
        balance[_to] = balance[_to] + _amount;
        balance[msg.sender] = balance[msg.sender] - _amount;
    }

    function burn(uint256 _amount) external onlyOwner {
        uint256 burnableCirculation = limit - circulation;
        require(_amount <= burnableCirculation, "Not enough burnable tokens based on the amount!");
        limit = limit - _amount;
    }
}