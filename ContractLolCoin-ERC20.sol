// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LolCoin {
    string public constant name = "Lol Coin";
    string public constant symbol = "LOL";
    uint8 public constant decimals = 18;
    uint256 private constant _totalSupply = 1000000000 * (10 ** uint256(decimals));
    address private _owner;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _stakedBalances;
    mapping(address => uint256) private _stakingStart;

    uint256 private _totalBurned; // Total amount of LOL burned
    uint256 private _totalSold; // Total amount of LOL sold

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TokensBurned(uint256 amount);
    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event TokenSold(address indexed seller, uint256 amount);
    event LotteryDraw(address indexed winner, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the contract owner can call this function");
        _;
    }

    constructor() {
        _owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
    }

    // Total supply of Lol Coin
    function totalSupply() external pure returns (uint256) {
        return _totalSupply;
    }

    // Get the balance of an address
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    // Get the staked balance of an address
    function stakedBalanceOf(address account) external view returns (uint256) {
        return _stakedBalances[account];
    }

    // Get the staking start time of an address
    function stakingStartOf(address account) external view returns (uint256) {
        return _stakingStart[account];
    }

    // Get the total amount of Lol sold
    function totalSold() external view returns (uint256) {
        return _totalSold;
    }

    // Stake Lol Coins to participate in staking
    function stake(uint256 amount) external {
        require(amount > 0, "Stake amount must be greater than zero");
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        _balances[msg.sender] -= amount;
        _stakedBalances[msg.sender] += amount;

        if (_stakingStart[msg.sender] == 0) {
            _stakingStart[msg.sender] = block.timestamp;
        }

        emit Staked(msg.sender, amount);
    }

    // Unstake Lol Coins and claim the rewards
    function unstake() external {
        require(_stakedBalances[msg.sender] > 0, "No staked balance");

        uint256 stakedAmount = _stakedBalances[msg.sender];
        uint256 stakingDuration = block.timestamp - _stakingStart[msg.sender];
        uint256 rewards = calculateRewards(stakedAmount, stakingDuration);

        _stakedBalances[msg.sender] = 0;
        _balances[msg.sender] += stakedAmount + rewards;

        emit Unstaked(msg.sender, stakedAmount);
    }

    // Internal function to calculate the staking rewards
    function calculateRewards(uint256 amount, uint256 duration) internal pure returns (uint256) {
        // Implement your own logic to calculate staking rewards based on the staked amount and duration
        // This is just a placeholder function and should be customized according to your specific staking model
        return amount * duration * 10 / (365 days);
    }

    // Buy Lol Coins with Ether (Applying 2% fee)
    function buyTokens() external payable {
        uint256 amount = msg.value;
        require(amount > 0, "You must send some Ether");
        
        uint256 boughtAmount = amount * (10 ** decimals) / tokenPrice();
        require(_balances[_owner] >= boughtAmount, "Insufficient tokens for sale");
        
        // Apply 2% fee to the bought amount
        uint256 feeAmount = boughtAmount * 2 / 100;
        _balances[_owner] -= boughtAmount - feeAmount;
        _balances[msg.sender] += boughtAmount - feeAmount;
        _totalSold += boughtAmount - feeAmount;
        
        emit Transfer(_owner, msg.sender, boughtAmount - feeAmount);
    }
    
    // Sell Lol Coins for Ether (Applying 5% fee)
    function sellTokens(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        
        // Apply 5% fee to the sold amount
        uint256 feeAmount = amount * 5 / 100;
        _balances[msg.sender] -= amount;
        _balances[_owner] += amount - feeAmount;
        _totalSold += amount - feeAmount;
        payable(msg.sender).transfer(amount - feeAmount);
        
        emit Transfer(msg.sender, _owner, amount - feeAmount);
    }

    // Internal transfer function
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "Invalid address");
        require(_balances[from] >= value, "Insufficient balance");

        // Calculate the burn amount (0.02% of the transaction value)
        uint256 burnAmount = value * 2 / 10000;
        uint256 transferAmount = value - burnAmount;

        _balances[from] -= value;
        _balances[to] += transferAmount;

        _totalBurned += burnAmount;

        // Check if the token reaches 50% of vendagem (50% sold)
        if (_totalBurned >= _totalSupply / 2) {
            // Distribute 0.5% of total supply to all holders
            uint256 lotteryReward = _totalSupply * 5 / 1000;
            uint256 socialActionsFund = _totalSupply * 30 / 100;
            _balances[_owner] += lotteryReward;
            _balances[address(0)] += socialActionsFund; // Sending to address(0) means burning tokens

            emit LotteryDraw(_owner, lotteryReward);
        }

        emit Transfer(from, to, transferAmount);
        emit TokensBurned(burnAmount);
    }

    // Internal approval function
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "Invalid address");
        require(spender != address(0), "Invalid address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    // Pause and unpause the contract in case of emergencies
    bool private _paused;
    
    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Contract is not paused");
        _;
    }

    function pause() external onlyOwner whenNotPaused {
        _paused = true;
    }

    function unpause() external onlyOwner whenPaused {
        _paused = false;
    }

    // Prevent accidental ether transfer to the contract
    receive() external payable {
        revert("Lol Coin contract does not accept ether");
    }
    
    // Get the current token price in Wei (1 Ether = X LOL)
    function tokenPrice() public view returns (uint256) {
        return address(this).balance / (_totalSupply - _totalBurned);
    }
}
