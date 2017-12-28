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

interface EtheremonTransformProcessor {
    function ableToLay(uint64 _objId) constant public returns(bool);
    function processRelease(uint64 _objId) public returns(bool);
    function getAdvanceLay(uint64 _objId) constant public returns(uint32);
    function getTransformClass(uint64 _objId) constant public returns(uint32);
    function fasterHatchFee(uint64 _objId, uint blockSize) constant public returns(uint256);
    function getAdvanceLayFee(uint64 _objId) constant public returns(uint256);
    function getTransformFee(uint64 _objId) constant public returns(uint256);
}

contract EtheremonTransform is EtheremonEnum, BasicAccessControl, SafeMath {
    uint8 constant public STAT_COUNT = 6;
    uint8 constant public STAT_MAX = 32;
    
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
        uint hatchBlock;
        bool hatched;
    }
    
    // hatching range
    uint16 public hatchStartTime = 1000;
    uint16 public hatchMaxTime = 9000;
     
    uint64 public totalEgg = 0;
    
    // linked smart contract
    address public dataContract;
    address public processorContract;
    
    address private lastHatchingAddress;
    mapping(uint64 => MonsterEgg) public eggs; // eggId
    mapping(address => uint64) public hatchingEggs;
    mapping(uint64 => uint64[]) public eggList; // objId -> [eggId]
    mapping(uint64 => bool) public transformed; //objId -> transformed
    
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
    
    modifier requireTransformProcessor {
        require(processorContract != address(0));
        _;
    }
    
    
    // constructor
    function EtheremonTransform(address _dataContract, address _processorContract) public {
        dataContract = _dataContract;
        processorContract = _processorContract;
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
    function setContract(address _dataContract, address _processorContract) onlyModerators external {
        dataContract = _dataContract;
        processorContract = _processorContract;
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
    
    
    // public
    
    function getObjClassId(uint64 _objId) requireDataContract constant public returns(uint32, address) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        uint32 _ = 0;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, _, _, obj.createTime) = data.getMonsterObj(_objId);
        return (obj.classId, obj.trainer);
    }
    
    function layEgg(uint64 _objId) requireDataContract requireTransformProcessor external {
        // make sure no hatching egg at the same time
        if (hatchingEggs[msg.sender] > 0) {
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

        EtheremonTransformProcessor processor = EtheremonTransformProcessor(processorContract);
        if (processor.ableToLay(_objId)) {
            totalEgg += 1;
            MonsterEgg storage egg = eggs[totalEgg];
            egg.objId = _objId;
            egg.eggId = totalEgg;
            egg.classId = obj.classId;
            egg.trainer = msg.sender;
            egg.hatchBlock = block.number + hatchStartTime + getRandom(hatchMaxTime, 0, lastHatchingAddress);
            egg.hatched = false;
            hatchingEggs[msg.sender] = totalEgg;
            
            // increase count
            eggList[_objId].push(totalEgg);
            EventLayEgg(msg.sender, _objId, totalEgg);
        }
    }
    
    function hatchEgg() requireDataContract requireTransformProcessor external {
        // use as a seed for random
        lastHatchingAddress = msg.sender;
        
        uint64 eggId = hatchingEggs[msg.sender];
        // not hatching any egg
        if (eggId == 0)
            revert();
        
        MonsterEgg storage egg = eggs[eggId];
        // no egg
        if (egg.eggId != eggId || egg.trainer != msg.sender) {
            revert();
        }
        // need more time
        if (egg.hatched == true || egg.hatchBlock > block.number) {
            revert();
        }
        
        uint64 objId = addNewObj(msg.sender, egg.classId);
        
        hatchingEggs[msg.sender] = 0;
        egg.hatched = true;
        EventHatchEgg(msg.sender, eggId, objId);
    }
    
    function increaseHatchingProcess(uint64 _objId, uint blockSize) requireDataContract requireTransformProcessor external payable  {
        uint64 eggId = hatchingEggs[msg.sender];
        // not hatching any egg
        if (eggId == 0)
            revert();
        MonsterEgg storage egg = eggs[eggId];
        // no egg
        if (egg.eggId != eggId || egg.trainer != msg.sender) {
            revert();
        }
        
        EtheremonTransformProcessor processor = EtheremonTransformProcessor(processorContract);
        uint256 fee = processor.fasterHatchFee(_objId, blockSize);
        if (msg.value < fee) {
            revert();
        }
        if (egg.hatchBlock < blockSize)
            egg.hatchBlock = 0;
        else
            egg.hatchBlock -= blockSize;
    }
    
    // gen a diffrent monster class egg
    function layAdvanceEgg(uint64 _objId) requireDataContract requireTransformProcessor external payable {
        uint32 classId;
        address owner;
        (classId, owner) = getObjClassId(_objId);
        if (classId == 0 || owner != msg.sender)
            revert();
            
        EtheremonTransformProcessor processor = EtheremonTransformProcessor(processorContract);
        uint256 fee = processor.getAdvanceLayFee(_objId);
        if (msg.value < fee) {
            revert();
        }
        
        uint32 classLayId = processor.getAdvanceLay(_objId);
        if (classLayId > 0 && classLayId != classId) {
            totalEgg += 1;
            MonsterEgg storage egg = eggs[totalEgg];
            egg.eggId = totalEgg;
            egg.objId = _objId;
            egg.classId = classLayId;
            egg.trainer = msg.sender;
            egg.hatchBlock = block.number + hatchStartTime + getRandom(hatchMaxTime, 0, lastHatchingAddress);
            hatchingEggs[msg.sender] = totalEgg;
            
            // increase count
            eggList[_objId].push(totalEgg);
            EventLayEgg(msg.sender, _objId, totalEgg);
        } else {
            revert();
        }
    }
    
    function release(uint64 _objId) requireDataContract requireTransformProcessor external payable {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        uint32 classId = 0;
        address owner = address(0);
        (classId, owner) = getObjClassId(_objId);
        if (classId == 0 || owner != msg.sender)
            revert();

        EtheremonTransformProcessor processor = EtheremonTransformProcessor(processorContract);
        if (processor.processRelease(_objId)) {
            data.removeMonsterIdMapping(msg.sender, _objId);
        }
        EventRelease(msg.sender, _objId);
    }
    
    function transform(uint64 _objId) requireDataContract requireTransformProcessor external payable {
        if (transformed[_objId] == true)
            revert();
        
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        uint32 classId = 0;
        address owner = address(0);
        (classId, owner) = getObjClassId(_objId);
        if (classId == 0 || owner != msg.sender)
            revert();

        EtheremonTransformProcessor processor = EtheremonTransformProcessor(processorContract);
        uint256 fee = processor.getTransformFee(_objId);
        if (msg.value < fee) {
            revert();
        }

        uint32 classTranformedId = processor.getTransformClass(_objId);
        if (classTranformedId > 0 && classTranformedId != classId) {
            // generate a new one 
            // add monster
            
            uint64 newObjId = addNewObj(msg.sender, classTranformedId);
            
            // remove old one
            data.removeMonsterIdMapping(msg.sender, _objId);
            EventTransform(msg.sender, _objId, newObjId);
        }
    }
    
    // read
    function countTotalEgg(uint64 _objId) constant external returns(uint) {
        return eggList[_objId].length;
    }
    
    function getEggId(uint64 _objId, uint index) constant external returns(uint64) {
        return eggList[_objId][index];
    }
    
    function getEggInfo(uint64 _eggId) constant external returns(uint64 objId, uint32 classId, address trainer, uint hatchBlock) {
        MonsterEgg memory egg = eggs[_eggId];
        return (egg.objId, egg.classId, egg.trainer, egg.hatchBlock);
    }
    
}