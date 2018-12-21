pragma solidity ^0.4.23;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract TRC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract CandyBox is Owned {
    /*
    * checks only candyManager address is calling
    */
    modifier onlyCandyManager {
        require(
            msg.sender == roleCandyManager ||
            msg.sender == owner
        ,"Only owner can do this");
        _;
    }
    address public roleCandyManager;

    TRC20Interface public token;
    bool isPause;
    // Number of candy
    uint public candyIdIndex_;
    // Maximum number of users available.
    uint maxReceiveNumber;
    // recovery limit time 3600 second
    uint recoveryLimitTime;
    // user has receive numbers
    mapping(address => uint) receiveNumbers;
    // user last receive time
    mapping(address => uint) receiveLastTime;
    // use left receive nubers, one hour recovery one
    mapping(address => uint) leftReceiveNumbers;
    // Less than one hour recovery time , second
    mapping(address => uint) leftRecoveryTime;
    // user blacklist
    mapping(address => uint) blacklist;


    // candys
    mapping(uint => Candy) candays;
    // candy has been receive amount
    mapping(uint => uint256) candyHasReceived;
    // The user can receive total token of the candy
    mapping(uint => uint256) candyTotal;
    // The order of the candy token, the numbers are big on the top
    mapping(uint => uint8) candyOrder;
    // Number of times each time
    mapping(uint => uint256) candyOnce;
    // Has it been deleted? 1 is deleted
    mapping(uint => uint8) candyIsDeleted;

    mapping(uint => string) candyImageUrl;
    mapping(uint => string) candyBgUrl;
    mapping(uint => string) candyTitle;
    mapping(uint => string) candyDesc;
    mapping(uint => string) candyLink;

    constructor() public {
        candyIdIndex_ = 1;
        maxReceiveNumber = 2;
        recoveryLimitTime = 3600;
        isPause = true;
        roleCandyManager = msg.sender;
    }

    struct Candy {
        address addr;
        string name;
    }

    function setPause(bool pause) public onlyOwner {
        isPause = pause;
    }

    function setCandyManager(address addr) public onlyOwner {
        roleCandyManager = addr;
    }

    function addCandy(
        address addr,
        string memory name,
        uint256 total,
        uint256 once,
        string memory imageUrl,
        string memory bgUrl,
        string memory title,
        string memory introduction,
        string memory link,
        uint8 order
    )
    public
    onlyCandyManager
    {
        candays[candyIdIndex_] = Candy(addr, name);
        candyTotal[candyIdIndex_] = total;
        candyOnce[candyIdIndex_] = once;
        candyOrder[candyIdIndex_] = order;

        candyImageUrl[candyIdIndex_] = imageUrl;
        candyBgUrl[candyIdIndex_] = bgUrl;
        candyTitle[candyIdIndex_] = title;
        candyDesc[candyIdIndex_] = introduction;
        candyLink[candyIdIndex_] = link;

        candyIdIndex_ += 1;
    }

    function editCandy(
        uint id,
        address addr,
        string memory name,
        uint256 total,
        uint256 once,
        string memory imageUrl,
        string memory bgUrl,
        string memory title,
        string memory introduction,
        string memory link,
        uint8 order
    )
    public
    onlyCandyManager
    {
        candays[id] = Candy(addr, name);
        candyTotal[id] = total;
        candyOnce[id] = once;
        candyOrder[id] = order;

        candyImageUrl[id] = imageUrl;
        candyBgUrl[id] = bgUrl;
        candyTitle[id] = title;
        candyDesc[id] = introduction;
        candyLink[id] = link;
    }

    function delCandy(uint id) public onlyCandyManager {
        candyIsDeleted[id] = 1;
    }

    function editCandy(uint id, string memory name, string memory introduction, uint256 once) public onlyCandyManager() {
        candays[id].name = name;
        candyDesc[id] = introduction;
        candyOnce[id] = once;
    }
    function editPubCandy(uint id, uint8 order, uint8 isDeleted) public onlyCandyManager() {
        candyOrder[id] = order;
        candyIsDeleted[id] = isDeleted;
    }
    function getCandy(uint id)
        public
        view
        returns (
            address,
            string memory,
            uint256,
            uint256,
            uint
        ) {
        return (
            candays[id].addr,
            candays[id].name,
            candyTotal[id],
            candyHasReceived[id],
            candyOnce[id]
        );
    }
    function getCandyDetail(uint _id)
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            uint8,
            uint8
        ) {
        return (
            candyImageUrl[_id],
            candyBgUrl[_id],
            candyTitle[_id],
            candyDesc[_id],
            candyLink[_id],
            candyIsDeleted[_id],
            candyOrder[_id]
        );
    }
    // User click and  receive the candy.
    function receive(uint id) public payable {
        require(!inBlacklist(msg.sender), 'In blacklist');
        require(canReceive(msg.sender), 'should wait one hour');
        require(isPause, 'Have pause');
        require(candyIsDeleted[id] < 1, 'Have delete');
        require(candyTotal[id]- candyHasReceived[id] - candyOnce[id] >= 0, 'Candy super hair');


        Candy memory candy = candays[id];
        receiveNumbers[msg.sender] += 1;
        uint lrn = (leftReceiveNumbers[msg.sender] + (now - receiveLastTime[msg.sender] + (recoveryLimitTime - leftRecoveryTime[msg.sender])) / recoveryLimitTime) - 1;
        lrn = lrn < 0 ? 0: lrn;
        leftReceiveNumbers[msg.sender] = lrn < maxReceiveNumber - 1 ? lrn : maxReceiveNumber - 1 ;
        leftRecoveryTime[msg.sender] = recoveryLimitTime - (now - receiveLastTime[msg.sender] + (recoveryLimitTime - leftRecoveryTime[msg.sender])) % recoveryLimitTime;
        receiveLastTime[msg.sender] = now;
        candyHasReceived[id] = candyHasReceived[id] + candyOnce[id];
        TRC20Interface t = TRC20Interface(candy.addr);
        t.transfer(msg.sender, candyOnce[id]);
    }
    // Retrieve candy
    function transferCandy(address _token, address _to, uint256 _amount) public onlyCandyManager returns (bool success){
        TRC20Interface t = TRC20Interface(_token);
        t.transfer(_to, _amount);
        return true;
    }
    // Total candys in the box.
    function total() public view returns (uint number){
        return candyIdIndex_;
    }
    function maxNumbers() public view returns (uint number){
        return maxReceiveNumber;
    }
    // User has receive candy numbers.
    function myNumbers(address addr) public view returns (uint number){
        return receiveNumbers[addr];
    }
    function myLastTime(address addr) public view returns (uint time){
        return receiveLastTime[addr];
    }
    // User last receive info.
    function myLastReceive(address addr) public view returns (uint num, uint time, uint left){
        return (leftReceiveNumbers[addr], receiveLastTime[addr], leftRecoveryTime[addr]);
    }
    // Add some user to blacklist
    function addBlacklist(address addr) public onlyCandyManager {
        blacklist[addr] = 1;
    }
    // Delete user from blacklist
    function delBlacklist(address addr) public onlyCandyManager {
        delete blacklist[addr];
    }

    function inBlacklist(address addr) public view returns (bool isin) {
        return blacklist[addr] > 0;
    }

    function canReceive(address addr) public view returns (bool can) {
        return (leftReceiveNumbers[addr] + (now - receiveLastTime[addr] + (recoveryLimitTime - leftRecoveryTime[addr])) / recoveryLimitTime) > 0;
    }
}
