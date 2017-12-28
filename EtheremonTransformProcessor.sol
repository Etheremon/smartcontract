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
        require(moderators[msg.sender] == true);
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
}

contract EtheremonDataBase is EtheremonEnum, BasicAccessControl, SafeMath {
    
    uint64 public totalMonster;
    uint32 public totalClass;
    
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

interface ProcessorInterface {
    function ableToLay(uint64 _objId) constant public returns(bool);
    function processRelease(uint64 _objId) public returns(bool);
    function getAdvanceLay(uint64 _objId) constant public returns(uint32);
    function getTransformClass(uint64 _objId) constant public returns(uint32);
    function fasterHatchFee(uint64 _objId, uint blockSize) constant public returns(uint256);
    function getAdvanceLayFee(uint64 _objId) constant public returns(uint256);
    function getTransformFee(uint64 _objId) constant public returns(uint256);
}

interface EtheremonTransform {
     function countTotalEgg(uint64 _objId) constant public returns(uint);
     function getEggInfo(uint64 _eggId) constant public returns(uint64 objId, uint32 classId, address trainer, uint hatchBlock);
}

interface EtheremonWorld {
    function getGen0COnfig(uint32 _classId) constant public returns(uint32, uint256, uint32);
    function getTrainerEarn(address _trainer) constant public returns(uint256);
    function getReturnFromMonster(uint64 _objId) constant public returns(uint256 current, uint256 total);
}

interface EtheremonBattle {
    function isOnBattle(uint64 _objId) constant external returns(bool);
    function getMonsterLevel(uint64 _objId) constant public returns(uint8);
}

interface EtheremonTradeInterface {
    function isOnTrading(uint64 _objId) constant external returns(bool);
}

contract EtheremonTransformProcessor is ProcessorInterface, EtheremonEnum, BasicAccessControl, SafeMath {
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
    
    uint8 public minLevelToLay = 30;
    
    // linked smart contract
    address public worldContract;
    address public dataContract;
    address public transformContract;
    address public battleContract;
    address public tradeContract;
    
    // moderators
    modifier requireDataContract {
        require(dataContract != address(0));
        _;
    }
    
    modifier requireTransformContract {
        require(transformContract != address(0));
        _;
    }
    
    modifier requireWorldContract {
        require(worldContract != address(0));
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
    
    function EtheremonTransformProcessor(address _dataContract, address _transformContract, address _worldContract, 
        address _battleContract, address _tradeContract) public {
        dataContract = _dataContract;
        transformContract = _transformContract;
        worldContract = _worldContract;
        battleContract = _battleContract;
        tradeContract = _tradeContract;
    }
    
     // admin & moderators
    function setContract(address _dataContract, address _transformContract, address _worldContract, 
        address _battleContract, address _tradeContract) onlyModerators external {
        dataContract = _dataContract;
        transformContract = _transformContract;
        worldContract = _worldContract;
        battleContract = _battleContract;
        tradeContract = _tradeContract;
    }
    
    function setMinLevelToLay(uint8 _value) onlyModerators external {
        minLevelToLay = _value;
    }
    
    // public 
    
    function ceil(uint a, uint m) pure public returns (uint) {
        return ((a + m - 1) / m) * m;
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
  
    function ableToLay(uint64 _objId) constant public returns(bool) {
        // in this update, only gen 0 has egg
        EtheremonBattle battle = EtheremonBattle(battleContract);
        EtheremonTransform transform = EtheremonTransform(transformContract);
        // can not release gen 0 
        uint32 classId;
        uint32 createIndex; 
        uint256 totalEarn;
        (classId, createIndex, totalEarn) = getObjInfo(_objId);
        
        if (classId > GEN0_NO && battle.getMonsterLevel(_objId) < minLevelToLay)
            return false;
        
        uint totalLayedEgg = transform.countTotalEgg(_objId);
        if (totalLayedEgg >= calculateMaxEggG0(_objId))
            return false;
        return true;
    }
    
    function processRelease(uint64 _objId) public returns(bool) {
        EtheremonBattle battle = EtheremonBattle(battleContract);
        EtheremonTradeInterface trade = EtheremonTradeInterface(tradeContract);
        if (battle.isOnBattle(_objId) || trade.isOnTrading(_objId))
            return false;
        // can not release gen 0 
        uint32 classId;
        uint32 createIndex; 
        uint256 totalEarn;
        (classId, createIndex, totalEarn) = getObjInfo(_objId);
        
        if (classId > GEN0_NO)
            return true;
        return false;
    }
    
    function getAdvanceLay(uint64 _objId) constant public returns(uint32) {
        // not available in this update
        return 0;
    }
    
    function getTransformClass(uint64 _objId) constant public returns(uint32) {
        EtheremonBattle battle = EtheremonBattle(battleContract);
        EtheremonTradeInterface trade = EtheremonTradeInterface(tradeContract);
        if (battle.isOnBattle(_objId) || trade.isOnTrading(_objId))
            return 0;
        // not available in this update
        return 0;
    }
    
    function fasterHatchFee(uint64 _objId, uint blockSize) constant public returns(uint256) {
        return 0;
    }
    
    function getAdvanceLayFee(uint64 _objId) constant public returns(uint256) {
        return 0;
    }
    
    function getTransformFee(uint64 _objId) constant public returns(uint256) {
        return 0;
    }
    
}