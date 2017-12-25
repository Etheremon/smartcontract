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
    bool public isMaintaining = false;

    function BasicAccessControl() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        if (msg.sender != owner) {
            require(moderators[msg.sender] == true);
        }
        _;
    }

    modifier isActive {
        require(isMaintaining == true);
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

contract EtheremonBattle is EtheremonEnum, BasicAccessControl, SafeMath {
    uint8 constant public STAT_COUNT = 6;
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
    
    // linked smart contract
    address public worldContract;
    address public dataContract;
    
    // global variable
    uint8 public maxLevel = 100;
    
    function EtheremonTransformProcessor(address _dataContract, address _worldContract) public {
        dataContract = _dataContract;
        worldContract = _worldContract;
    }
    
     // admin & moderators
    function setContract(address _dataContract, address _worldContract) onlyModerators public {
        dataContract = _dataContract;
        worldContract = _worldContract;
    }
    
    function setMaxLevel(uint8 _maxLevel) onlyModerators public {
        maxLevel = _maxLevel;
    }
    
    // public 
    function getLevel(uint32 exp) view internal returns (uint8) {
        uint8 level = 1;
        uint8 requirement = maxLevel;
        while(level < maxLevel && exp > requirement) {
            exp -= requirement;
            level += 1;
            requirement = requirement * 12 / 10 + 5;
        }
        return level;
    }
    
    function getMonsterLevel(uint64 _objId) constant public returns(uint8) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        uint32 _ = 0;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, _, _, obj.createTime) = data.getMonsterObj(_objId);
     
        return getLevel(obj.exp);
    }
    
    function getMonsterCP(uint64 _objId) constant public returns(uint64) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        uint32 _ = 0;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, _, _, obj.createTime) = data.getMonsterObj(_objId);
     
    
        uint256 total = 0;
        uint i = 0;
        uint baseSize = data.getSizeArrayType(ArrayType.STAT_BASE, obj.monsterId);
        if (baseSize == 0) {
            // use base as the stat is not generated
            for(i=0; i < STAT_COUNT; i+=1) {
                total += data.getElementInArrayType(ArrayType.STAT_START, uint64(obj.classId), i);
                total += safeMult(data.getElementInArrayType(ArrayType.STAT_STEP, uint64(obj.classId), i), getLevel(obj.exp));
            }
        } else {
            for(i=0; i < baseSize; i+=1) {
                total += data.getElementInArrayType(ArrayType.STAT_BASE, obj.monsterId, i);
                total += safeMult(data.getElementInArrayType(ArrayType.STAT_STEP, uint64(obj.classId), i), getLevel(obj.exp));
            }
        }
        
        return uint64(total/baseSize);
    }
    
    // Battle will be released in next update
    
}