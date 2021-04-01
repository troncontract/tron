pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;

//合约地址：TJP7qCGbg1kcVwqvR3vPhBZWMHMqiLfafb   tron-mainnet.token.im
// token 合约地址 TApU6QvHUJTRcB9udS5LiyfbttWontdmGk
contract Creator {
    address payable public creator;
    /**
        @dev constructor
    */
    constructor() public {
        creator = msg.sender;
    }

    // allows execution by the creator only
    modifier creatorOnly {
        assert(msg.sender == creator);
        _;
    }
}


contract DEFI_DEMO is Creator {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;


    using SafeMath for uint256;
    uint  is_first = 0;
    uint256 constant public TIME_STEP = 30 ;//1 days;

    uint256 constant public PROJECT_FEE = 20;
    uint256 constant public PERCENTS_DIVIDER = 1000;

    uint256 constant public NODE_LEVEL_MAX = 4;

    address public usdtToken = address(0x419fdc31bb3cd5b504610f13aa696dc5c7ecdc8e55);

    IERC20 public USDT = IERC20(address(0x419fdc31bb3cd5b504610f13aa696dc5c7ecdc8e55));

    address payable public projectAddress;




    struct node_config {
        uint256 id;
        uint256 price;
        uint256 pre_price;
        uint256 last_price;
        uint256 percent;
        uint256 day;
        uint256 sign1;
        uint256 sign2;
        uint256 sure_duration;
        uint256 sign_duration;
    }

    struct node_order {
        uint256 price;
        uint256 pre_price;
        uint256 last_price;
        uint256 percent;
        uint256 level;
        uint256 day;
        uint256 sign1;
        uint256 sign2;
        uint256 sure_duration;
        uint256 sign_duration;
        uint256 status;
        uint256 operation_time;
        uint256 deadline_time;
        bool IsOver;
    }

    node_config[]  public NODE_CONFIG;

    struct User {
        bool IsNode;
        address referrer;
        node_order[] nodeOrders;
        uint256 nodeState; //当前节点状态 0 初始化 1 预约 2 买入 3 收益中 4 冻结中 5 出局 6 失效 7 确定付款
        node_order nodeOrder;
    }

    mapping(address => User) public users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Withdrawndividend(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);
    event NodeFee(address indexed from, address indexed to, uint256 Amount);
    event UpNodeFee(address indexed from, address indexed to, uint256 Amount);
    event WithDrawnNodeFee(address indexed user, uint256 amount);

    event preNode1(address indexed referrer, uint256 level);
    event preNode2(address indexed sender, uint256 amount);
    event preNode3(uint256 id, uint256 price);
    event preNode4(uint256 id, uint256 price);
    event sureNode1(address indexed sender, uint256 nodeState);
    event sureNode2(uint256 nodeState, uint deadline_time);


    constructor() public {
//              initialize(address(0x41BDE07764CB70611B522C552A3B391287FAFF2CA8));
        initialize();
    }

    modifier IsInitialized {
        require(projectAddress != address(0), "not Initialized");
        _;
    }

    bytes4 private constant transferFrom = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

    bytes4 private constant transfer = bytes4(keccak256(bytes('transfer(address,uint256)')));

    function SafeUsdtTransferFrom(address from, address to, uint value) private {
        (bool success, bytes memory data) = usdtToken.call(abi.encodeWithSelector(transferFrom, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    function SafeUsdtTransfer(address to, uint value) private {
        (bool success, bytes memory data) = usdtToken.call(abi.encodeWithSelector(transfer, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }
//    function initialize(address payable projectAddr) public payable creatorOnly {
//
//        require(projectAddress == address(0) && projectAddr != address(0), "initialize only would call once");
//        require(!isContract(projectAddr));
//        projectAddress = projectAddr;
    function initialize() public payable creatorOnly {
        if(is_first==0){
            projectAddress = projectAddr ;
            is_first = 1;
        }
        NODE_CONFIG.push(node_config({id:0,price : 5 * 1000000,pre_price:1 * 1000000,last_price:4 * 1000000, percent : 5, day:5,sign1:19,sign2:31,sure_duration:5,sign_duration:5}));
        NODE_CONFIG.push(node_config({id:1,price : 10 * 1000000,pre_price:2 * 1000000,last_price:8 * 1000000, percent : 10, day:5,sign1:19,sign2:31,sure_duration:5,sign_duration:5}));
        NODE_CONFIG.push(node_config({id:2,price : 30 * 1000000,pre_price:6 * 1000000,last_price:24 * 1000000, percent : 10, day:10,sign1:20,sign2:32,sure_duration:5,sign_duration:5}));
        NODE_CONFIG.push(node_config({id:3,price : 50 * 1000000,pre_price:10 * 1000000,last_price:40 * 1000000, percent : 12, day:15,sign1:20,sign2:32,sure_duration:5,sign_duration:5}));
        NODE_CONFIG.push(node_config({id:4,price : 100 * 1000000,pre_price:20 * 1000000,last_price:80 * 1000000, percent : 15, day:15,sign1:20,sign2:32,sure_duration:5,sign_duration:5}));

    }
    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
        - 32075
        + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
        + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
        - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
        - OFFSET19700101;

        _days = uint(__days);
    }
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }
    // 更改收币地址  //只有创建者可以修改
    function change_pro_addr(address payable projectAddr) public  creatorOnly {
        projectAddress = projectAddr;
    }
    //当前节点状态 0 初始化 1 预约 2 确认中 3 收益中 4 冻结中 5 出局 6 失效
    function preNode(address referrer, uint256 level) public payable IsInitialized {
        emit preNode1(referrer, level);
        emit preNode2(msg.sender, msg.value);
        require(!isContract(msg.sender) && (tx.origin == msg.sender));


        //level from 0 ~ 2
        node_config memory level_conf = NODE_CONFIG[level];
        require(level >= 0 && level < NODE_CONFIG.length);

        emit preNode3(level_conf.id, level_conf.price);
        //        require(level_conf.bought < level_conf.max, "counter over");
        User storage user = users[msg.sender];
        if(user.IsNode==true){
            require(!(user.nodeState == 1 ||user.nodeState == 2 ||user.nodeState == 3)   , "node state error");
        }else{
            user.referrer = referrer;
        }
        require(level >= user.nodeOrder.level,'level need >= last level');
        uint  last_time = addDays(now,10);
        user.nodeOrder = node_order(level,level_conf.price,level_conf.pre_price,level_conf.last_price,level_conf.percent,level_conf.day,
            level_conf.sign1,level_conf.sign2,level_conf.sure_duration,level_conf.sign_duration,1,now,last_time,false );
        if(user.nodeState == 4){
            user.nodeOrder.status = 5;
        }

        user.nodeOrders[0]= user.nodeOrder ;
        user.IsNode = true;
        //        user.nodeOrder = nodeOrder;
        user.nodeState = 1;
        uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        projectAddress.transfer(fee);
        emit preNode4(user.nodeOrder.status , fee);
//        emit FeePayed(msg.sender, fee);
        //        SafeUsdtTransferFrom(msg.sender, projectAddress,
        //            level_conf.pre_price);
    }
    function preNodeNoAddress(uint256 level) public payable IsInitialized {

        emit preNode2(msg.sender, msg.value);
        require(!isContract(msg.sender) && (tx.origin == msg.sender));


        //level from 0 ~ 2
        node_config memory level_conf = NODE_CONFIG[level];
        require(level >= 0 && level < NODE_CONFIG.length);

        emit preNode3(level_conf.id, level_conf.price);
        //        require(level_conf.bought < level_conf.max, "counter over");
        User storage user = users[msg.sender];
        if(user.IsNode==true){
            require(!(user.nodeState == 1 ||user.nodeState == 2 ||user.nodeState == 3)   , "node state error");
        }
        require(level >= user.nodeOrder.level,'level need >= last level');
        uint  last_time = addDays(now,10);
        user.nodeOrder = node_order(level,level_conf.price,level_conf.pre_price,level_conf.last_price,level_conf.percent,level_conf.day,
            level_conf.sign1,level_conf.sign2,level_conf.sure_duration,level_conf.sign_duration,1,now,last_time,false );
        if(user.nodeState == 4){
            user.nodeOrder.status = 5;
        }

        user.nodeOrders[0]= user.nodeOrder ;
        user.IsNode = true;
        //        user.nodeOrder = nodeOrder;
        user.nodeState = 1;
        uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        projectAddress.transfer(fee);
        emit preNode4(user.nodeOrder.status , fee);
        //        emit FeePayed(msg.sender, fee);
        //        SafeUsdtTransferFrom(msg.sender, projectAddress,
        //            level_conf.pre_price);
    }
    function sureNode() public payable IsInitialized {
        User storage user = users[msg.sender];
        emit sureNode1(msg.sender,user.nodeState);
        require(user.IsNode == true , "IsNode is true");
        require(user.nodeState == 1 , "node state is not 1");
        if(now >= user.nodeOrder.deadline_time){
            user.nodeState = 6;
        }
        require(now < user.nodeOrder.deadline_time , "deadline_time");
        uint  year = getYear(now);
        uint  month = getMonth(now);
        uint  day = getDay(now);
        uint h1 = user.nodeOrder.sign1 /2 ;
        uint m1 = user.nodeOrder.sign1 % 2;

        uint h2 = user.nodeOrder.sign2 /2 ;
        uint m2 = user.nodeOrder.sign2 % 2;
        uint  time1 =  timestampFromDateTime(year,month,day,h1,30 * m1,0);
        uint xx1 =  30 * m1+user.nodeOrder.sure_duration;
        uint  time11 =  timestampFromDateTime(year,month,day,h1,xx1,0);
        uint  time2 =  timestampFromDateTime(year,month,day,h2,30 * m2,0);
        uint xx = 30 * m2+user.nodeOrder.sure_duration;
        uint  t22 =  timestampFromDateTime(year,month,day,h2,xx,0);
//        require( (now>=time1 && now <= time11) ||  (now>=time2 && now <= t22), " time is error");
        user.nodeState = 2;
        user.nodeOrder.operation_time = now;
        uint xxxxx = user.nodeOrder.sign_duration;

        user.nodeOrder.deadline_time = addHours(now,xxxxx);
//        emit sureNode2(user.nodeState, user.nodeOrder.deadline_time);
    }

    function buyNode() public payable IsInitialized {
        User storage user = users[msg.sender];
        require(user.IsNode == true , "IsNode is true");
        require(user.nodeState ==2 , "node state is not 7");
        if(now >= user.nodeOrder.deadline_time){
            user.nodeState = 6;
        }
        require(now < user.nodeOrder.deadline_time , "deadline_time");
        uint  year = getYear(now);
        uint  month = getMonth(now);
        uint  day = getDay(now);

        user.nodeState = 3;
        user.nodeOrder.operation_time = now;
        uint  signDuration =  addDays(now,user.nodeOrder.day);
        user.nodeOrder.deadline_time = signDuration;
        uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        projectAddress.transfer(fee);

        emit FeePayed(msg.sender, fee);
    }

    //NODE_CONFIG.push(node_config({id:1,price : 5000 * 1000000,pre_price:1000 * 1000000,last_price:4000 * 1000000, percent : 5, day:5,sign1:19,sign2:31,sure_duration:5,sign_duration:3}));
    function updateSignTime(uint256 level,uint256 sign1,uint256 sign2) public payable IsInitialized {
        require(msg.sender == projectAddress , "projectAddress is error");
        require(level >= 0 && level < NODE_CONFIG.length);

        require(sign1 > 0 && sign1 <= 48);
        require(sign2 > 0 && sign2 <= 48);
        node_config storage level_conf = NODE_CONFIG[level];
        level_conf.sign1 = sign1;
        level_conf.sign2 = sign2;
    }





    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {size := extcodesize(addr)}
        return size > 0;
    }

}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function add64(uint256 a, uint64 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? b : a;
    }

    function min64(uint256 a, uint64 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }


    function sub64(uint256 a, uint64 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function mul64(uint256 a, uint64 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function div64(uint256 a, uint64 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);
}

