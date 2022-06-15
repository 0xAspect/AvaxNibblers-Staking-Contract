pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';


interface IERC20funcs {
        function transfer(address dst, uint wad) external returns (bool);
        function transferFrom(address from, address to, uint wad) external returns (bool);
        function balanceOf(address user) external view returns (uint);
        function approve(address _spender, uint _value) external returns (bool);
        function increaseApproval (address _spender, uint _value) external returns (bool);

        }


contract Nibbles is Ownable, ERC20("Tasty Sewer Treats", "NIBBLES") {


    address trinketAddr;    
    uint YieldFactor;
    uint dailyMaxTotalYield;


    mapping (address => uint) public stakingBalance;
    mapping (address => bool) public isStaking;
    mapping (address => uint) public startTime;

    event NibblesSent(address indexed user, uint256 reward);

    event Unstaked(address indexed user);

    constructor(address _trinketAddr, uint _factor){
        setTrinketAddr(_trinketAddr);
        setYieldFactor(_factor);
    }

    function setTrinketAddr(address _trinket) public onlyOwner {
        trinketAddr = _trinket;
    }

    function setYieldFactor(uint _factor) public onlyOwner {
        YieldFactor = _factor;
    }
    
    function setDailyMaxTotalYield(uint _amount) public onlyOwner {
        dailyMaxTotalYield = _amount;
    }

    function returnTrinketAddr() public view returns (address) {
        return trinketAddr;
    }


    function stake(uint _amount) public {
        require(_amount > 0, 'You cannot stake zero tokens');
        IERC20funcs(trinketAddr).transferFrom(msg.sender, address(this), _amount);
        
        if (isStaking[msg.sender] = true) {
            claimYield(msg.sender);
        }
        
        stakingBalance[msg.sender] =  _amount + stakingBalance[msg.sender];
        isStaking[msg.sender] = true;
        startTime[msg.sender] = block.timestamp;
    }

    function unstake(uint _amount) public {
        require(isStaking[msg.sender] = true, 'You are not staking tokens');
        require(stakingBalance[msg.sender] > 0, 'You do not have funds to fetch');
        require(_amount <= stakingBalance[msg.sender], 'trying to unstake more than stake');
        claimYield(msg.sender);
        stakingBalance[msg.sender] = stakingBalance[msg.sender] - _amount;
        IERC20funcs(trinketAddr).transfer(msg.sender, _amount);
        if (stakingBalance[msg.sender] == 0){
            isStaking[msg.sender] = false;
        }
        emit Unstaked(msg.sender);
    }

    function claimYield(address _user) public {
        require(isStaking[_user] == true || startTime[_user] != block.timestamp);
        uint yield = calculateYield(_user);
            if (yield > 0) {
                 _mint(_user, yield );
                startTime[_user] = block.timestamp;
                emit NibblesSent(_user, yield);
            }
    }



    function calculateYield(address _user) public view returns(uint) {
        uint time = stakeTime(_user);
        uint bal = ((time * stakingBalance[_user]) * YieldFactor) / 100;
        return bal;
    }

    function stakeTime(address _user) public view returns(uint){
        uint end = block.timestamp;
        uint start  = startTime[_user];
        return (end - start);
    }

    function userStakingBalance(address _address) public view returns(uint){
            return stakingBalance[_address];
    }
}