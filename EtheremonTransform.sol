pragma solidity ^0.4.16;

// copyright contact@Etheremon.com

contract SafeMath {

    /* function assert(bool assertion) internal { */
    /*   if (!assertion) { */
    /*     throw; */
    /*   } */
    /* }      // assert no longer needed once solidity is on 0.4.10 */

    function safeAdd(uint256 x, uint256 y) pure internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) pure internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) pure internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

}

contract BasicAccessControl {
    address public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping (address => bool) public moderators;
    bool public isMaintaining = true;

    function BasicAccessControl() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }

    modifier isActive {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }


    function AddModerator(address _newModerator) onlyOwner public {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }
    
    function RemoveModerator(address _oldModerator) onlyOwner public {
        if (moderators[_oldModerator] == true) {
            moderators[_oldModerator] = false;
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) onlyOwner public {
        isMaintaining = _isMaintaining;
    }
}

contract EtheremonEnum {

    enum ResultCode {
        SUCCESS,
        ERROR_CLASS_NOT_FOUND,
        ERROR_LOW_BALANCE,
        ERROR_SEND_FAIL,
        ERROR_NOT_TRAINER,
        ERROR_NOT_ENOUGH_MONEY,
        ERROR_INVALID_AMOUNT,
        ERROR_OBJ_NOT_FOUND,
        ERROR_OBJ_INVALID_OWNERSHIP
    }
    
    enum ArrayType {
        CLASS_TYPE,
        STAT_STEP,
        STAT_START,
        STAT_BASE,
        OBJ_SKILL
    }
    
    enum PropertyType {
        ANCESTOR,
        XFACTOR
    }
}

contract EtheremonDataBase is EtheremonEnum, BasicAccessControl, SafeMath {
    
    uint64 public totalMonster;
    uint32 public totalClass;
    
    // write
    function addElementToArrayType(ArrayType _type, uint64 _id, uint8 _value) onlyModerators public returns(uint);
    function removeElementOfArrayType(ArrayType _type, uint64 _id, uint8 _value) onlyModerators public returns(uint);
    function setMonsterClass(uint32 _classId, uint256 _price, uint256 _returnPrice, bool _catchable) onlyModerators public returns(uint32);
    function addMonsterObj(uint32 _classId, address _trainer, string _name) onlyModerators public returns(uint64);
    function setMonsterObj(uint64 _objId, string _name, uint32 _exp, uint32 _createIndex, uint32 _lastClaimIndex) onlyModerators public;
    function increaseMonsterExp(uint64 _objId, uint32 amount) onlyModerators public;
    function decreaseMonsterExp(uint64 _objId, uint32 amount) onlyModerators public;
    function removeMonsterIdMapping(address _trainer, uint64 _monsterId) onlyModerators public;
    function addMonsterIdMapping(address _trainer, uint64 _monsterId) onlyModerators public;
    function clearMonsterReturnBalance(uint64 _monsterId) onlyModerators public returns(uint256 amount);
    function collectAllReturnBalance(address _trainer) onlyModerators public returns(uint256 amount);
    function transferMonster(address _from, address _to, uint64 _monsterId) onlyModerators public returns(ResultCode);
    function addExtraBalance(address _trainer, uint256 _amount) onlyModerators public returns(uint256);
    function deductExtraBalance(address _trainer, uint256 _amount) onlyModerators public returns(uint256);
    function setExtraBalance(address _trainer, uint256 _amount) onlyModerators public;
    
    // read
    function getSizeArrayType(ArrayType _type, uint64 _id) constant public returns(uint);
    function getElementInArrayType(ArrayType _type, uint64 _id, uint _index) constant public returns(uint8);
    function getMonsterClass(uint32 _classId) constant public returns(uint32 classId, uint256 price, uint256 returnPrice, uint32 total, bool catchable);
    function getMonsterObj(uint64 _objId) constant public returns(uint64 objId, uint32 classId, address trainer, uint32 exp, uint32 createIndex, uint32 lastClaimIndex, uint createTime);
    function getMonsterName(uint64 _objId) constant public returns(string name);
    function getExtraBalance(address _trainer) constant public returns(uint256);
    function getMonsterDexSize(address _trainer) constant public returns(uint);
    function getMonsterObjId(address _trainer, uint index) constant public returns(uint64);
    function getExpectedBalance(address _trainer) constant public returns(uint256);
    function getMonsterReturn(uint64 _objId) constant public returns(uint256 current, uint256 total);
}

contract EtheremonTransformData {
    uint64 public totalEgg = 0;
    function getHatchingEggId(address _trainer) constant external returns(uint64);
    function getHatchingEggData(address _trainer) constant external returns(uint64, uint64, uint32, address, uint, uint64);
    function getTranformedId(uint64 _objId) constant external returns(uint64);
    function countEgg(uint64 _objId) constant external returns(uint);
    
    function setHatchTime(uint64 _eggId, uint _hatchTime) external;
    function setHatchedEgg(uint64 _eggId, uint64 _newObjId) external;
    function addEgg(uint64 _objId, uint32 _classId, address _trainer, uint _hatchTime) external returns(uint64);
    function setTranformed(uint64 _objId, uint64 _newObjId) external;
}

contract EtheremonWorld is EtheremonEnum {
    
    function getGen0COnfig(uint32 _classId) constant public returns(uint32, uint256, uint32);
    function getTrainerEarn(address _trainer) constant public returns(uint256);
    function getReturnFromMonster(uint64 _objId) constant public returns(uint256 current, uint256 total);
    function getClassPropertyValue(uint32 _classId, PropertyType _type, uint index) constant external returns(uint32);
}

interface EtheremonBattle {
    function isOnBattle(uint64 _objId) constant external returns(bool);
    function getMonsterLevel(uint64 _objId) constant public returns(uint8);
}

interface EtheremonTradeInterface {
    function isOnTrading(uint64 _objId) constant external returns(bool);
}

contract EtheremonTransform is EtheremonEnum, BasicAccessControl, SafeMath {
    uint8 constant public STAT_COUNT = 6;
    uint8 constant public STAT_MAX = 32;
    uint8 constant public GEN0_NO = 24;
    
    struct MonsterClassAcc {
        uint32 classId;
        uint256 price;
        uint256 returnPrice;
        uint32 total;
        bool catchable;
    }

    struct MonsterObjAcc {
        uint64 monsterId;
        uint32 classId;
        address trainer;
        string name;
        uint32 exp;
        uint32 createIndex;
        uint32 lastClaimIndex;
        uint createTime;
    }
    
    struct MonsterEgg {
        uint64 eggId;
        uint64 objId;
        uint32 classId;
        address trainer;
        uint hatchTime;
        uint64 newObjId;
    }
    
    struct BasicObjInfo {
        uint32 classId;
        address owner;
        uint8 level;
    }
    
    // hatching range
    uint16 public hatchStartTime = 2; // hour
    uint16 public hatchMaxTime = 46; // hour
    uint public removeHatchingTimeFee = 0.05 ether; // ETH
    mapping(uint32 => uint8) public layingEggLevels;
    mapping(uint32 => uint8) public layingEggDeductions;
    mapping(uint32 => uint8) public transformLevels;
    mapping(uint32 => uint32) public transformClasses;

    mapping(uint8 => uint32) public levelExps;
    address private lastHatchingAddress;
    
    // linked smart contract
    address public dataContract;
    address public worldContract;
    address public transformDataContract;
    address public battleContract;
    address public tradeContract;
    
    // events
    event EventLayEgg(address indexed trainer, uint64 objId, uint64 eggId);
    event EventHatchEgg(address indexed trainer, uint64 eggId, uint64 objId);
    event EventTransform(address indexed trainer, uint64 oldObjId, uint64 newObjId);
    event EventRelease(address indexed trainer, uint64 objId);
    
    // modifier
    
    modifier requireDataContract {
        require(dataContract != address(0));
        _;
    }
    
    modifier requireTransformDataContract {
        require(transformDataContract != address(0));
        _;
    }
    
    modifier requireBattleContract {
        require(battleContract != address(0));
        _;
    }
    
    modifier requireTradeContract {
        require(tradeContract != address(0));
        _;        
    }
    
    
    // constructor
    function EtheremonTransform(address _dataContract, address _worldContract, address _transformDataContract, address _battleContract, address _tradeContract) public {
        dataContract = _dataContract;
        worldContract = _worldContract;
        transformDataContract = _transformDataContract;
        battleContract = _battleContract;
        tradeContract = _tradeContract;
    }
    
    // helper
    function getRandom(uint16 maxRan, uint8 index, address priAddress) constant public returns(uint8) {
        uint256 genNum = uint256(block.blockhash(block.number-1)) + uint256(priAddress);
        for (uint8 i = 0; i < index && i < 6; i ++) {
            genNum /= 256;
        }
        return uint8(genNum % maxRan);
    }
    
    function addNewObj(address _trainer, uint32 _classId) private returns(uint64) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        uint64 objId = data.addMonsterObj(_classId, _trainer, "..name me...");
        for (uint i=0; i < STAT_COUNT; i+= 1) {
            uint8 value = getRandom(STAT_MAX, uint8(i), lastHatchingAddress) + data.getElementInArrayType(ArrayType.STAT_START, uint64(_classId), i);
            data.addElementToArrayType(ArrayType.STAT_BASE, objId, value);
        }
        return objId;
    }
    
    // admin & moderators
    function setContract(address _dataContract, address _worldContract, address _transformDataContract, address _battleContract, address _tradeContract) onlyModerators external {
        dataContract = _dataContract;
        worldContract = _worldContract;
        transformDataContract = _transformDataContract;
        battleContract = _battleContract;
        tradeContract = _tradeContract;
    }
    
    function updateHatchingRange(uint16 _start, uint16 _max) onlyModerators external {
        hatchStartTime = _start;
        hatchMaxTime = _max;
    }

    function withdrawEther(address _sendTo, uint _amount) onlyModerators external {
        // no user money is kept in this contract, only trasaction fee
        if (_amount > this.balance) {
            revert();
        }
        _sendTo.transfer(_amount);
    }

    function setConfigClass(uint32 _classId, uint8 _layingLevel, uint8 _layingCost, uint8 _transformLevel, uint32 _tranformClass) onlyModerators external {
        layingEggLevels[_classId] = _layingLevel;
        layingEggDeductions[_classId] = _layingCost;
        transformLevels[_classId] = _transformLevel;
        transformClasses[_classId] = _tranformClass;
    }
    
    function setConfig(uint _removeHatchingTimeFee) onlyModerators external {
        removeHatchingTimeFee = _removeHatchingTimeFee;
    }

    function genLevelExp() onlyModerators external {
        uint8 level = 1;
        uint32 requirement = 100;
        uint32 sum = requirement;
        while(level <= 100) {
            levelExps[level] = sum;
            level += 1;
            requirement = (requirement * 11) / 10 + 5;
            sum += requirement;
        }
    }    
    
    function removeHatchingTimeWithToken(address _trainer) isActive onlyModerators requireDataContract requireTransformDataContract external {
        EtheremonTransformData transformData = EtheremonTransformData(transformDataContract);
        MonsterEgg memory egg;
        (egg.eggId, egg.objId, egg.classId, egg.trainer, egg.hatchTime, egg.newObjId) = transformData.getHatchingEggData(_trainer);
        // not hatching any egg
        if (egg.eggId == 0 || egg.trainer != _trainer || egg.newObjId > 0)
            revert();
        
        transformData.setHatchTime(egg.eggId, 0);
    }    
    
    // public

    function ceil(uint a, uint m) pure public returns (uint) {
        return ((a + m - 1) / m) * m;
    }

    function getLevel(uint32 exp) view public returns (uint8) {
        uint8 minIndex = 1;
        uint8 maxIndex = 100;
        uint8 currentIndex;
     
        while (minIndex < maxIndex) {
            currentIndex = (minIndex + maxIndex) / 2;
            if (exp < levelExps[currentIndex])
                maxIndex = currentIndex;
            else
                minIndex = currentIndex + 1;
        }

        return minIndex;
    }

    function getObjInfo(uint64 _objId) constant public returns(uint32 classId, uint32 createIndex, uint256 totalEarn) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        EtheremonWorld world = EtheremonWorld(worldContract);
        
        uint256 current = 0;
        uint256 total = 0;
        (current, total) = world.getReturnFromMonster(_objId);
        
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(_objId);
        return (obj.classId, obj.createIndex, total);
    }
    
    function getObjClassId(uint64 _objId) requireDataContract constant public returns(uint32, address, uint8) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        uint32 _ = 0;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, _, _, obj.createTime) = data.getMonsterObj(_objId);
        return (obj.classId, obj.trainer, getLevel(obj.exp));
    }
    
    function getClassCheckOwner(uint64 _objId, address _trainer) requireDataContract constant public returns(uint32) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        uint32 _ = 0;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, _, _, obj.createTime) = data.getMonsterObj(_objId);
        if (_trainer != obj.trainer)
            return 0;
        return obj.classId;
    }

    function calculateMaxEggG0(uint64 _objId) constant public returns(uint) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        EtheremonWorld world = EtheremonWorld(worldContract);
        
        uint32 classId;
        uint32 createIndex; 
        uint256 totalEarn;
        uint256 oPrice = 0;
        uint32 oTotal = 0;
        (classId, createIndex, totalEarn) = getObjInfo(_objId);
        (classId, oPrice, oTotal) = world.getGen0COnfig(classId);
        
        // the one from egg can not lay
        if (createIndex > oTotal)
            return 0;
        if (classId == 20 || classId == 21)
            return 0;
        
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(classId);
        if (classId > GEN0_NO || class.returnPrice == 0)
            return 0;

        // calculate agv price
        uint256 avgPrice = oPrice;
        uint rate = oPrice/class.returnPrice;
        if (oTotal > rate) {
            uint k = oTotal - rate;
            avgPrice = (oTotal * oPrice + class.returnPrice * k * (k+1) / 2) / oTotal;
        }
        uint256 catchPrice = oPrice;            
        if (createIndex > rate) {
            catchPrice += class.returnPrice * safeSubtract(createIndex, rate);
        }
        if (totalEarn >= catchPrice) {
            return 0;
        }
        return ceil((catchPrice - totalEarn)*15*1000/avgPrice, 10000)/10000;
    }
    
    function canLayEgg(uint64 _objId, uint32 _classId, uint32 _level) constant public returns(bool) {
        if (_classId <= GEN0_NO) {
            EtheremonTransformData transformData = EtheremonTransformData(transformDataContract);
            // legends
            if (transformData.countEgg(_objId) >= calculateMaxEggG0(_objId))
                return false;
            return true;
        } else {
            if (layingEggLevels[_classId] == 0 || _level < layingEggLevels[_classId])
                return false;
            return true;
        }
    }
    
    function layEgg(uint64 _objId) isActive requireDataContract requireTransformDataContract external {
        EtheremonTransformData transformData = EtheremonTransformData(transformDataContract);
        // make sure no hatching egg at the same time
        if (transformData.getHatchingEggId(msg.sender) > 0) {
            revert();
        }
        
        // check obj 
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        uint32 _ = 0;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, _, _, obj.createTime) = data.getMonsterObj(_objId);
        if (obj.monsterId != _objId || obj.trainer != msg.sender) {
            revert();
        }
        
        // check lay egg condition
        uint8 currentLevel = getLevel(obj.exp);
        uint8 afterLevel = 0;
        if (!canLayEgg(_objId, obj.classId, currentLevel))
            revert();
        if (layingEggDeductions[obj.classId] > currentLevel)
            revert();
        afterLevel = currentLevel - layingEggDeductions[obj.classId];

        // add egg 
        uint64 eggId = transformData.addEgg(obj.monsterId, obj.classId, msg.sender, block.timestamp + (hatchStartTime + getRandom(hatchMaxTime, 0, lastHatchingAddress)) * 3600);
        
        // deduct exp 
        data.decreaseMonsterExp(_objId, levelExps[currentLevel] - levelExps[afterLevel]);
        EventLayEgg(msg.sender, _objId, eggId);
    }
    
    function hatchEgg() isActive requireDataContract requireTransformDataContract external {
        // use as a seed for random
        lastHatchingAddress = msg.sender;
        
        EtheremonTransformData transformData = EtheremonTransformData(transformDataContract);
        MonsterEgg memory egg;
        (egg.eggId, egg.objId, egg.classId, egg.trainer, egg.hatchTime, egg.newObjId) = transformData.getHatchingEggData(msg.sender);
        // not hatching any egg
        if (egg.eggId == 0 || egg.trainer != msg.sender)
            revert();
        // need more time
        if (egg.newObjId > 0 || egg.hatchTime > block.timestamp) {
            revert();
        }
        
        uint64 objId = addNewObj(msg.sender, egg.classId);
        transformData.setHatchedEgg(egg.eggId, objId);
        EventHatchEgg(msg.sender, egg.eggId, objId);
    }
    
    function removeHatchingTime() isActive requireDataContract requireTransformDataContract external payable  {
        EtheremonTransformData transformData = EtheremonTransformData(transformDataContract);
        MonsterEgg memory egg;
        (egg.eggId, egg.objId, egg.classId, egg.trainer, egg.hatchTime, egg.newObjId) = transformData.getHatchingEggData(msg.sender);
        // not hatching any egg
        if (egg.eggId == 0 || egg.trainer != msg.sender || egg.newObjId > 0)
            revert();
        
        if (msg.value != removeHatchingTimeFee) {
            revert();
        }
        transformData.setHatchTime(egg.eggId, 0);
    }

    
    function checkAncestors(uint32 _classId, address _trainer, uint64 _a1, uint64 _a2, uint64 _a3) constant public returns(bool) {
        EtheremonWorld world = EtheremonWorld(worldContract);
        uint index = 0;
        uint32 temp = 0;
        // check ancestor
        uint32[3] memory ancestors;
        uint32[3] memory requestAncestors;
        for (index = 0; index < 3; index++) {
            ancestors[index] = world.getClassPropertyValue(_classId, PropertyType.ANCESTOR, index);
        }
            
        if (_a1 > 0) {
            temp = getClassCheckOwner(_a1, _trainer);
            if (temp == 0)
                return false;
            requestAncestors[0] = temp;
        }
        if (_a2 > 0) {
            temp = getClassCheckOwner(_a2, _trainer);
            if (temp == 0)
                return false;
            requestAncestors[1] = temp;
        }
        if (_a3 > 0) {
            temp = getClassCheckOwner(_a3, _trainer);
            if (temp == 0)
                return false;
            requestAncestors[2] = temp;
        }
            
        if (requestAncestors[0] > 0 && (requestAncestors[0] == requestAncestors[1] || requestAncestors[0] == requestAncestors[2]))
            return false;
        if (requestAncestors[1] > 0 && (requestAncestors[1] == requestAncestors[2]))
            return false;
                
        if (requestAncestors.length != ancestors.length)
            return false;
        for (index = 0; index < ancestors.length; index++) {
            temp = ancestors[index];
            if (temp > 0 && temp != requestAncestors[0]  && temp != requestAncestors[1] && temp != requestAncestors[2])
                return false;
        }
        
        return true;
    }
    
    function transform(uint64 _objId, uint64 _a1, uint64 _a2, uint64 _a3) isActive requireDataContract requireTransformDataContract external payable {
        EtheremonTransformData transformData = EtheremonTransformData(transformDataContract);
        if (transformData.getTranformedId(_objId) > 0)
            revert();
        
        EtheremonBattle battle = EtheremonBattle(battleContract);
        EtheremonTradeInterface trade = EtheremonTradeInterface(tradeContract);
        if (battle.isOnBattle(_objId) || trade.isOnTrading(_objId))
            revert();
        
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        
        BasicObjInfo memory objInfo;
        (objInfo.classId, objInfo.owner, objInfo.level) = getObjClassId(_objId);
        uint32 transformClass = transformClasses[objInfo.classId];
        if (objInfo.classId == 0 || objInfo.owner != msg.sender)
            revert();
        if (transformLevels[objInfo.classId] == 0 || objInfo.level < transformLevels[objInfo.classId])
            revert();
        if (transformClass == 0)
            revert();
        
        
        // gen0 - can not transform if it has bonus egg 
        if (objInfo.classId <= GEN0_NO) {
            // legends
            if (getBonusEgg(_objId) > 0)
                revert();
        } else {
            if (!checkAncestors(objInfo.classId, msg.sender, _a1, _a2, _a3))
                revert();
        }
        
        uint64 newObjId = addNewObj(msg.sender, transformClass);
        // remove old one
        data.removeMonsterIdMapping(msg.sender, _objId);
        transformData.setTranformed(_objId, newObjId);
        EventTransform(msg.sender, _objId, newObjId);
    }
    
    // read
    function getBonusEgg(uint64 _objId) constant public returns(uint) {
        EtheremonTransformData transformData = EtheremonTransformData(transformDataContract);
        uint totalBonusEgg = calculateMaxEggG0(_objId);
        if (totalBonusEgg > 0) {
            return (totalBonusEgg - transformData.countEgg(_objId));
        }
        return 0;
    }
    
}