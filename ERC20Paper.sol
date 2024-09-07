// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.26;

contract Paper {
    mapping (address => uint256) private balance;
    mapping (address => uint256) private allowedSpenders;
    address public tokenOwner;
    uint256 public limit;
    uint256 private circulation;
    string public name;
    string public symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == tokenOwner, "Caller is not owner!");

        _;
    }

    modifier allowedSpender(uint256 _amount) {
        require(_amount <= allowedSpenders[msg.sender], "Spender is not allowed to spend the amount of token owner tokens!");

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

    constructor(string memory _name, string memory _symbol, uint256 _limit, uint _initialTreasuryPercentage) {
        tokenOwner = msg.sender;
        name = _name;
        symbol = _symbol;
        limit = _limit;
        uint bps = _initialTreasuryPercentage * 100;
        uint initialTreasury = _limit * bps / 10_000;
        mint(msg.sender, initialTreasury);
    }

    function mint(address _wallet, uint256 _amount) public onlyOwner belowMintedLimit(_amount) {
        balance[_wallet] = balance[_wallet] + _amount;
        circulation = circulation + _amount;
    }

    function transfer(address recipient, uint256 amount) public enoughBalance(msg.sender, amount) {
        balance[recipient] = balance[recipient] + amount;
        balance[msg.sender] = balance[msg.sender] - amount;
        emit Transfer(msg.sender, recipient, amount);
    }

    function burn(uint256 _amount) external onlyOwner {
        uint256 burnableCirculation = limit - circulation;
        require(_amount <= burnableCirculation, "Not enough burnable tokens based on the amount!");
        limit = limit - _amount;
    }

    function totalSupply() public view returns (uint256) {
        return circulation;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balance[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        require(owner == tokenOwner, "Allowance is only available for token owner balance!");
        return allowedSpenders[spender];
    }
    
    function approve(address spender, uint256 amount) public onlyOwner enoughBalance(tokenOwner, amount) {
        allowedSpenders[spender] = amount;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public allowedSpender(amount) enoughBalance(tokenOwner, amount) {
        require(sender == tokenOwner, "Allowance is only available for token owner balance!");
        balance[recipient] = balance[recipient] + amount;
        balance[sender] = balance[sender] - amount;
        emit Transfer(sender, recipient, amount);
    }
}