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

    enum PropertyType {
        ANCESTOR,
        XFACTOR
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

interface EtheremonTradeInterface {
    function isOnTrading(uint64 _objId) constant external returns(bool);
}

contract EtheremonGateway is EtheremonEnum, BasicAccessControl {
    // using for battle contract later
    function increaseMonsterExp(uint64 _objId, uint32 amount) onlyModerators public;
    function decreaseMonsterExp(uint64 _objId, uint32 amount) onlyModerators public;
    
    // read 
    function isGason(uint64 _objId) constant external returns(bool);
    function getObjBattleInfo(uint64 _objId) constant external returns(uint32 classId, uint32 exp, bool isGason, 
        uint ancestorLength, uint xfactorsLength);
    function getClassPropertySize(uint32 _classId, PropertyType _type) constant external returns(uint);
    function getClassPropertyValue(uint32 _classId, PropertyType _type, uint index) constant external returns(uint32);
}

contract EtheremonCastleContract is BasicAccessControl{
    uint32 public totalCastle = 0;
    uint64 public totalBattle = 0;
    
    function getCastlePrice(uint32 _castleId) constant external returns(uint256);
    function getCastleBasicInfo(address owner) constant external returns(uint32, uint);
    function getCastleBasicInfoById(uint32 _castleId) constant external returns(uint, address);
    function countActiveCastle() constant external returns(uint);
    function getCastleObjInfo(uint32 _castleId) constant external returns(uint64, uint64, uint64, uint64, uint64, uint64);
    function getCastleStats(uint32 _castleId) constant external returns(string, address, uint256, uint32, uint32, uint32, uint);
    function isOnCastle(uint32 _castleId, uint64 _objId) constant external returns(bool);
    function getCastleWinLose(uint32 _castleId) constant external returns(uint32, uint32, uint256, uint32);

    function setCastle(address _trainer, string _name, uint64 _a1, uint64 _a2, uint64 _a3, uint64 _s1, uint64 _s2, uint64 _s3) onlyModerators external returns(uint32 currentCastleId);
    function setCastlePrice(uint32 _castleId, uint256 _price, uint32 _minBattle) onlyModerators external;
    function addBattleLog(uint32 _castleId, address _attacker, uint8 _ran1, uint8 _ran2, uint8 _ran3, bool _win) onlyModerators external returns(uint64);
    function addBattleMonsterLog(uint64 _battleId, uint64 _objId, uint32 _exp, uint _index) onlyModerators external;
    function removeCastleFromActive(uint32 _castleId) onlyModerators external;
}

contract EtheremonBattle is EtheremonEnum, BasicAccessControl, SafeMath {
    uint8 constant public NO_MONSTER = 3;
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
    
    struct BattleMonsterData {
        uint64 a1;
        uint64 a2;
        uint64 a3;
        uint64 s1;
        uint64 s2;
        uint64 s3;
    }

    struct AttackData {
        uint64 aa1;
        uint64 as1;
        uint64 as2;
        uint64 as3;
        uint64 ba1;
        uint64 bs1;
        uint64 bs2;
        uint64 bs3;
    }
    
    struct MonsterBattleLog {
        uint64 objId;
        uint32 exp;
    }
    
    struct BattleLogData {
        address castleOwner;
        uint64 battleId;
        uint32 castleId;
        uint256 castleBonus;
        uint castleIndex;
        uint32[6] monsterExp;
        uint8[3] randoms;
        bool win;
    }

    // event
    event EventCreateCastle(address indexed owner, uint32 castleId);
    event EventAttackCastle(address indexed attacker, uint32 castleId, bool result);
    event EventDestroyCastle(uint32 indexed castleId, address destroyer, bool hasBonus);
    event EventRemoveCastle(uint32 indexed castleId);
    
    // linked smart contract
    address public worldContract;
    address public dataContract;
    address public tradeContract;
    address public castleContract;
    
    // global variable
    mapping(uint8 => uint8) typeAdvantages;
    uint8 public ancestorBuffPercentage = 4;
    uint8 public gasonBuffPercentage = 8;
    uint8 public typeBuffPercentage = 20;
    uint256 public castleMinFee = 0.1 ether;
    uint8 public castleDestroyBonus = 50;// percentage
    uint8 public maxLevel = 100;
    uint16 public maxActiveCastle = 30;
    uint8 public maxRandomRound = 5;
    uint8 public minDestroyBattle = 10; // battles
    uint8 public minDestroyRate = 40; // percentage
    uint8 public minHpDeducted = 10;
    
    uint256 public totalEarn = 0;
    uint256 public totalWithdraw = 0;
    
    address private lastAttacker = address(0x0);
    
    // modifier
    modifier requireDataContract {
        require(dataContract != address(0));
        _;
    }
    
    modifier requireTradeContract {
        require(tradeContract != address(0));
        _;
    }
    
    modifier requireCastleContract {
        require(castleContract != address(0));
        _;
    }
    
    modifier requireWorldContract {
        require(worldContract != address(0));
        _;
    }


    function EtheremonBattle(address _dataContract, address _worldContract, address _tradeContract, address _castleContract) public {
        dataContract = _dataContract;
        worldContract = _worldContract;
        tradeContract = _tradeContract;
        castleContract = _castleContract;
    }
    
     // admin & moderators
    function setTypeAdvantages() onlyModerators external {
        typeAdvantages[1] = 14;
        typeAdvantages[2] = 16;
        typeAdvantages[3] = 8;
        typeAdvantages[4] = 9;
        typeAdvantages[5] = 2;
        typeAdvantages[6] = 11;
        typeAdvantages[7] = 3;
        typeAdvantages[8] = 5;
        typeAdvantages[9] = 15;
        typeAdvantages[11] = 18;
        // skipp 10
        typeAdvantages[12] = 7;
        typeAdvantages[13] = 6;
        typeAdvantages[14] = 17;
        typeAdvantages[15] = 13;
        typeAdvantages[16] = 12;
        typeAdvantages[17] = 1;
        typeAdvantages[18] = 4;
    } 
     
    function withdrawEther(address _sendTo, uint _amount) onlyModerators external {
        if (_amount > this.balance) {
            revert();
        }
        uint256 validAmount = safeSubtract(totalEarn, totalWithdraw);
        if (_amount > validAmount) {
            revert();
        }
        totalWithdraw += _amount;
        _sendTo.transfer(_amount);
    }
    
    function setContract(address _dataContract, address _worldContract, address _tradeContract, address _castleContract) onlyModerators external {
        dataContract = _dataContract;
        worldContract = _worldContract;
        tradeContract = _tradeContract;
        castleContract = _castleContract;
    }
    
    function setConfig(uint8 _ancestorBuffPercentage, uint8 _gasonBuffPercentage, uint8 _typeBuffPercentage, uint256 _castleMinFee, 
        uint8 _maxLevel, uint16 _maxActiveCastle, uint8 _maxRandomRound, uint8 _minHpDeducted, uint8 _castleDestroyBonus) onlyModerators external{
        ancestorBuffPercentage = _ancestorBuffPercentage;
        gasonBuffPercentage = _gasonBuffPercentage;
        typeBuffPercentage = _typeBuffPercentage;
        castleMinFee = _castleMinFee;
        maxLevel = _maxLevel;
        maxActiveCastle = _maxActiveCastle;
        maxRandomRound = _maxRandomRound;
        minHpDeducted = _minHpDeducted;
        castleDestroyBonus = _castleDestroyBonus;
    }
    
    // public 
    function getRandom(uint8 maxRan, uint8 index, address priAddress) constant public returns(uint8) {
        uint256 genNum = uint256(block.blockhash(block.number-1)) + uint256(priAddress);
        for (uint8 i = 0; i < index && i < 6; i ++) {
            genNum /= 256;
        }
        return uint8(genNum % maxRan);
    }
    
    function getLevel(uint32 exp) view public returns (uint8) {
        uint8 level = 1;
        uint32 requirement = maxLevel;
        while(level < maxLevel && exp > requirement) {
            exp -= requirement;
            level += 1;
            requirement = requirement * 11 / 10 + 5;
        }
        return level;
    }
    
    function getGainExp(uint32 _exp1, uint32 _exp2, bool _win, bool _isAttacker) view public returns(uint32){
        uint8 halfLevel1 = getLevel(_exp1)/2;
        uint32 gainExp = 1;
        uint256 rate = (21 ** uint256(halfLevel1)) * 10 / (20 ** uint256(halfLevel1));
        rate = rate * rate / 100;
        if (_win) {
            if (_isAttacker) {
                gainExp = uint32(30 * rate);
            } else {
                gainExp = uint32(15 * rate);
            }
        } else {
            gainExp = uint32(6 * rate);
        }
        
        uint8 level2 = getLevel(_exp2);
        if (halfLevel1* 2 > level2) {
            gainExp = gainExp * (halfLevel1 * 2 - level2) * 112 / 100;
        }
        return gainExp;
    }
    
    function getMonsterLevel(uint64 _objId) constant external returns(uint32, uint8) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        uint32 _ = 0;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, _, _, obj.createTime) = data.getMonsterObj(_objId);
     
        return (obj.exp, getLevel(obj.exp));
    }
    
    function getMonsterClassId(uint64 _objId) constant public returns(uint32) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        uint32 _ = 0;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, _, _, obj.createTime) = data.getMonsterObj(_objId);
        return obj.classId;
    }
    
    function getMonsterCP(uint64 _objId) constant external returns(uint64) {
        uint16[6] memory stats;
        uint32 classId = 0;
        uint32 exp = 0;
        (classId, exp, stats) = getCurrentStats(_objId);
        
        uint256 total;
        for(uint i=0; i < STAT_COUNT; i+=1) {
            total += stats[i];
        }
        return uint64(total/STAT_COUNT);
    }
    
    function isOnBattle(uint64 _objId) constant external returns(bool) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        EtheremonCastleContract castle = EtheremonCastleContract(castleContract);
        uint32 castleId;
        uint castleIndex = 0;
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(_objId);
        (castleId, castleIndex) = castle.getCastleBasicInfo(obj.trainer);
        if (castleId > 0 && castleIndex > 0)
            return castle.isOnCastle(castleId, _objId);
        return false;
    }
    
    function isValidOwner(uint64 _objId, address _owner) constant public returns(bool) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(_objId);
        return (obj.trainer == _owner);
    }
    
    function getObjExp(uint64 _objId) constant public returns(uint32, uint32) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        uint32 _ = 0;
        (_objId, obj.classId, obj.trainer, obj.exp, _, _, obj.createTime) = data.getMonsterObj(_objId);
        return (obj.classId, obj.exp);
    }
    
    function getCurrentStats(uint64 _objId) constant public returns(uint32, uint32, uint16[6]){
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        uint16[6] memory stats;
        uint32 classId;
        uint32 exp;
        (classId, exp) = getObjExp(_objId);
        if (classId == 0)
            return (classId, exp, stats);
        
        uint i = 0;
        uint8 level = getLevel(exp);
        uint baseSize = data.getSizeArrayType(ArrayType.STAT_BASE, _objId);
        if (baseSize != STAT_COUNT) {
            for(i=0; i < STAT_COUNT; i+=1) {
                stats[i] += data.getElementInArrayType(ArrayType.STAT_START, uint64(classId), i);
                stats[i] += uint16(safeMult(data.getElementInArrayType(ArrayType.STAT_STEP, uint64(classId), i), level));
            }
        } else {
            for(i=0; i < STAT_COUNT; i+=1) {
                stats[i] += data.getElementInArrayType(ArrayType.STAT_BASE, _objId, i);
                stats[i] += uint16(safeMult(data.getElementInArrayType(ArrayType.STAT_STEP, uint64(classId), i), level));
            }
        }
        return (classId, exp, stats);
    }
    
    function checkGasonEffect(uint32 _classId, uint64 _gasSonObjId) constant public returns(uint8){
        if (_gasSonObjId == 0)
            return 0;
        EtheremonGateway gateway = EtheremonGateway(worldContract);
        uint32 gasClassId;
        uint32 exp;
        bool isGason; 
        uint temp;
        (gasClassId, exp, isGason, temp, temp) = gateway.getObjBattleInfo(_gasSonObjId);
        if (!isGason)
            return 0;

        EtheremonDataBase data = EtheremonDataBase(dataContract);
        temp = data.getSizeArrayType(ArrayType.CLASS_TYPE, _classId);
        uint typeGasSize = data.getSizeArrayType(ArrayType.CLASS_TYPE, gasClassId);
        uint8 aType = 0;
        uint8 bType = 0;
        if (temp > 0)
            temp -= 1;
        for (; temp >= 0; temp--) {
            aType = data.getElementInArrayType(ArrayType.CLASS_TYPE, uint64(_classId), temp);
            for (uint j = 0; j < typeGasSize; j++) {
                bType = data.getElementInArrayType(ArrayType.CLASS_TYPE, uint64(gasClassId), j);
                if (aType == bType)
                    return 2;
            }
        }
        return 1;
    }
    
    function getSupportIncreasingStats(uint64 _objId, uint64 _s1, uint64 _s2, uint64 _s3) constant public returns(uint16[6]){
        uint16[6] memory stats;
        uint32 objClassId = getMonsterClassId(_objId);
        uint32 s1ClassId = getMonsterClassId(_s1);
        uint32 s2ClassId = getMonsterClassId(_s2);
        uint32 s3ClassId = getMonsterClassId(_s3);
        
        EtheremonGateway gateway = EtheremonGateway(worldContract);
        // check ancestors
        uint i =0;
        uint8 countEffect = 0;
        uint ancestorSize = gateway.getClassPropertySize(objClassId, PropertyType.ANCESTOR);
        if (ancestorSize > 0) {
            
            uint32 ancestorClass = 0;
            for (i=0; i < ancestorSize; i ++) {
                ancestorClass = gateway.getClassPropertyValue(objClassId, PropertyType.ANCESTOR, i);
                if (ancestorClass == s1ClassId || ancestorClass == s2ClassId || ancestorClass == s3ClassId) {
                    countEffect += 1;
                }
            }
            if (countEffect > 0) {
                for(i=0; i < STAT_COUNT; i+=1) {
                    stats[i] = countEffect * ancestorBuffPercentage;
                }
            }
        }
        // check gason
        countEffect = checkGasonEffect(objClassId, _s1);
        countEffect += checkGasonEffect(objClassId, _s2);
        countEffect += checkGasonEffect(objClassId, _s3);
        // gason increase attack and special attack 
        // hp, atk, def, spa, spd, sp
        if (countEffect > 0) {
            stats[1] += gasonBuffPercentage * countEffect;
            stats[3] += gasonBuffPercentage * countEffect;
        }
        
        return stats;
    }
    
    function hasAdvantage(uint32 _aClassId, uint32 _bClassId) constant public returns(bool, bool) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        
        uint type1Size = data.getSizeArrayType(ArrayType.CLASS_TYPE, _aClassId);
        uint type2Size = data.getSizeArrayType(ArrayType.CLASS_TYPE, _bClassId);
        uint8 aType = 0;
        uint8 bType = 0;
        bool aHasAdvantage = false;
        bool bHasAdvantage = false;
        for (uint i = 0; i < type1Size; i++) {
            aType = data.getElementInArrayType(ArrayType.CLASS_TYPE, uint64(_aClassId), i);
            for (uint j = 0; j < type2Size; j++) {
                bType = data.getElementInArrayType(ArrayType.CLASS_TYPE, uint64(_bClassId), j);
                if (typeAdvantages[aType] == bType) {
                    aHasAdvantage = true;
                }
                if (typeAdvantages[bType] == aType) {
                    bHasAdvantage = true;
                }
            }
        }
        
        return (aHasAdvantage, bHasAdvantage);
    }
    
    function safeDeduct(uint16 a, uint16 b) pure private returns(uint16){
        if (a > b) {
            return a - b;
        }
        return 0;
    }
    
    function calHpDeducted(uint16 _attack, uint16 _specialAttack, uint16 _defense, uint16 _specialDefense, bool _lucky) view public returns(uint16){
        if (_lucky) {
            _attack = _attack * 2;
            _specialAttack = _specialAttack * 2;
        }
        uint16 hpDeducted = safeDeduct(_attack, _defense * 3 /4);
        uint16 hpSpecialDeducted = safeDeduct(_specialAttack, _specialDefense* 3 / 4);
        if (hpDeducted < minHpDeducted && hpSpecialDeducted < minHpDeducted)
            return minHpDeducted;
        if (hpDeducted > hpSpecialDeducted)
            return hpDeducted;
        return hpSpecialDeducted;
    }
    
    function calculateBattleStats(AttackData att) constant private returns(uint32 aExp, uint16[6] aStats, uint32 bExp, uint16[6] bStats) {
        uint32 aClassId = 0;
        (aClassId, aExp, aStats) = getCurrentStats(att.aa1);
        uint32 bClassId = 0;
        (bClassId, bExp, bStats) = getCurrentStats(att.ba1);
        
        uint16[6] memory aIncreaseStats;
        aIncreaseStats = getSupportIncreasingStats(att.aa1, att.as1, att.as2, att.as3);
        uint16[6] memory bIncreaseStats;
        bIncreaseStats = getSupportIncreasingStats(att.ba1, att.bs1, att.bs2, att.bs3);
        
        bool aHasAdvantage = false;
        bool bHasAdvantage = false;
        (aHasAdvantage, bHasAdvantage) = hasAdvantage(aClassId, bClassId);
        if (aHasAdvantage) {
            aIncreaseStats[1] += typeBuffPercentage;
            aIncreaseStats[3] += typeBuffPercentage;
        }
        if (bHasAdvantage) {
            bIncreaseStats[1] += typeBuffPercentage;
            bIncreaseStats[3] += typeBuffPercentage;
        }
        
        for (uint i = 0; i < STAT_COUNT; i++) {
            aStats[i] += aStats[i] *  aIncreaseStats[i] / 100;
            bStats[i] += bStats[i] *  bStats[i] / 100;
        }
    }
    
    function attack(AttackData att) constant private returns(uint32 aExp, uint32 bExp, uint8 ran, bool win) {
        uint16[6] memory aStats;
        uint16[6] memory bStats;
        (aExp, aStats, bExp, bStats) = calculateBattleStats(att);
        
        ran = getRandom(maxRandomRound, 0, lastAttacker);
        uint16 round = 0;
        while (aStats[0] > 0 && bStats[0] > 0) {
            if (aStats[5] > bStats[5]) {
                if (round % 2 == 0) {
                    // a attack 
                    bStats[0] = safeDeduct(bStats[0], calHpDeducted(aStats[1], aStats[3], bStats[2], bStats[4], round==ran));
                } else {
                    aStats[0] = safeDeduct(aStats[0], calHpDeducted(bStats[1], bStats[3], aStats[2], aStats[4], round==ran));
                }
                
            } else {
                if (round % 2 != 0) {
                    bStats[0] = safeDeduct(bStats[0], calHpDeducted(aStats[1], aStats[3], bStats[2], bStats[4], round==ran));
                } else {
                    aStats[0] = safeDeduct(aStats[0], calHpDeducted(bStats[1], bStats[3], aStats[2], aStats[4], round==ran));
                }
            }
            round+= 1;
        }
        
        win = aStats[0] >= bStats[0];
    }
    
    function destroyCastle(uint32 _castleId) private returns(uint256){
        EtheremonCastleContract castle = EtheremonCastleContract(castleContract);
        uint32 totalWin;
        uint32 totalLose;
        uint256 price;
        uint32 minBattle;
        (totalWin, totalLose, price, minBattle) = castle.getCastleWinLose(_castleId);
        if (totalWin + totalLose > minBattle) {
            if (totalWin * 100 / totalLose < minDestroyRate) {
                castle.removeCastleFromActive(_castleId);
                return price;
            }
        }
        return 0;
    }
    
    // public
    function setCastle(string _name, uint64 _a1, uint64 _a2, uint64 _a3, uint64 _s1, uint64 _s2, uint64 _s3) requireDataContract 
        requireTradeContract requireCastleContract payable external {
        if (_a1 == 0 || _a2 == 0 || _a3 == 0)
            revert();
        // make sure none of etheremon is on trade
        EtheremonTradeInterface trade = EtheremonTradeInterface(tradeContract);
        if (!trade.isOnTrading(_a1) || !trade.isOnTrading(_a2) || !trade.isOnTrading(_a3) || 
            !trade.isOnTrading(_s1) || !trade.isOnTrading(_s2) || !trade.isOnTrading(_s3))
            revert();
        
        if (!isValidOwner(_a1, msg.sender) || !isValidOwner(_a2, msg.sender) || !isValidOwner(_a3, msg.sender))
            revert();
        if (_s1 > 0 && !isValidOwner(_s1, msg.sender))
            revert();
        if (_s2 > 0 && !isValidOwner(_s2, msg.sender))
            revert();
        if (_s3 > 0 && !isValidOwner(_s3, msg.sender))
            revert();
        
        EtheremonCastleContract castle = EtheremonCastleContract(castleContract);
        uint32 castleId;
        uint castleIndex = 0;
        (castleId, castleIndex) = castle.getCastleBasicInfo(msg.sender);
        if (castleId == 0) {
            if (castle.countActiveCastle() > uint(maxActiveCastle))
                revert();
            if (msg.value < castleMinFee) {
                revert();
            }
            totalEarn += msg.value - (msg.value * castleDestroyBonus / 100);
            castleId = castle.setCastle(msg.sender, _name, _a1, _a2, _a3, _s1, _s2, _s3);
            castle.setCastlePrice(castleId, (msg.value * castleDestroyBonus / 100), uint32(msg.value * minDestroyBattle / castleMinFee));
        } else {
            castle.setCastle(msg.sender, _name, _a1, _a2, _a3, _s1, _s2, _s3);
        }
        
        EventCreateCastle(msg.sender, castleId);
    }
    
    function removeCastle(uint32 _castleId) requireCastleContract external {
        EtheremonCastleContract castle = EtheremonCastleContract(castleContract);
        uint index;
        address owner;
        (index, owner) = castle.getCastleBasicInfoById(_castleId);
        if (owner != msg.sender)
            revert();
        if (index > 0)
            castle.removeCastleFromActive(_castleId);
        EventRemoveCastle(_castleId);
    }
    
    function attackCastle(uint32 _castleId, uint64 _aa1, uint64 _aa2, uint64 _aa3, uint64 _as1, uint64 _as2, uint64 _as3) requireDataContract 
        requireTradeContract requireCastleContract external {
        if (_aa1 == 0 || _aa2 == 0 || _aa3 == 0)
            revert();
        // make sure none of etheremon is on trade
        EtheremonTradeInterface trade = EtheremonTradeInterface(tradeContract);
        if (!trade.isOnTrading(_aa1) || !trade.isOnTrading(_aa2) || !trade.isOnTrading(_aa3) || 
            !trade.isOnTrading(_as1) || !trade.isOnTrading(_as2) || !trade.isOnTrading(_as3))
            revert();
        
        EtheremonCastleContract castle = EtheremonCastleContract(castleContract);
        BattleLogData memory log;
        (log.castleIndex, log.castleOwner) = castle.getCastleBasicInfoById(_castleId);
        if (log.castleId == 0 || log.castleIndex == 0)
            revert();
        
        EtheremonGateway gateway = EtheremonGateway(worldContract);
        BattleMonsterData memory b;
        (b.a1, b.a2, b.a3, b.s1, b.s2, b.s3) = castle.getCastleObjInfo(_castleId);
        lastAttacker = msg.sender;
        // match 1
        uint8 countWin = 0;
        AttackData memory att;
        att.aa1 = _aa1;
        att.as1 = _as1;
        att.as2 = _as2;
        att.as3 = _as3;
        att.ba1 = b.a1;
        att.bs1 = b.s1;
        att.bs2 = b.s2;
        
        (log.monsterExp[0], log.monsterExp[3], log.randoms[0], log.win) = attack(att);
        gateway.increaseMonsterExp(att.aa1, getGainExp(log.monsterExp[3], log.monsterExp[0], log.win, true));
        gateway.increaseMonsterExp(att.ba1, getGainExp(log.monsterExp[0], log.monsterExp[3], !log.win, false));
        if (log.win)
            countWin += 1;
        
        att.aa1 = _aa2;
        att.ba1 = b.a2;
        (log.monsterExp[1], log.monsterExp[4], log.randoms[1], log.win) = attack(att);
        gateway.increaseMonsterExp(att.aa1, getGainExp(log.monsterExp[4], log.monsterExp[1], log.win, true));
        gateway.increaseMonsterExp(att.ba1, getGainExp(log.monsterExp[1], log.monsterExp[4], !log.win, false));
        if (log.win)
            countWin += 1;   

        att.aa1 = _aa3;
        att.ba1 = b.a3;
        (log.monsterExp[2], log.monsterExp[5], log.randoms[2], log.win) = attack(att);
        gateway.increaseMonsterExp(att.aa1, getGainExp(log.monsterExp[5], log.monsterExp[2], log.win, true));
        gateway.increaseMonsterExp(att.ba1, getGainExp(log.monsterExp[2], log.monsterExp[5], !log.win, false));
        if (log.win)
            countWin += 1; 
        
        log.battleId = castle.addBattleLog(_castleId, msg.sender, log.randoms[0], log.randoms[1], log.randoms[2], !(countWin>=2));
        castle.addBattleMonsterLog(log.battleId, b.a1, log.monsterExp[3], 0);
        castle.addBattleMonsterLog(log.battleId, b.a2, log.monsterExp[4], 0);
        castle.addBattleMonsterLog(log.battleId, b.a3, log.monsterExp[5], 0);
        castle.addBattleMonsterLog(log.battleId, b.s1, 0, 0);
        castle.addBattleMonsterLog(log.battleId, b.s2, 0, 0);
        castle.addBattleMonsterLog(log.battleId, b.s3, 0, 0);
        
        castle.addBattleMonsterLog(log.battleId, _aa1, log.monsterExp[0], 0);
        castle.addBattleMonsterLog(log.battleId, _aa2, log.monsterExp[1], 0);
        castle.addBattleMonsterLog(log.battleId, _aa3, log.monsterExp[2], 0);
        castle.addBattleMonsterLog(log.battleId, _as1, 0, 0);
        castle.addBattleMonsterLog(log.battleId, _as2, 0, 0);
        castle.addBattleMonsterLog(log.battleId, _as3, 0, 0);
    
        log.castleBonus = destroyCastle(_castleId);
        if (log.castleBonus  > 0) {
            // send bonus if smart contract has enough money 
            if (this.balance > log.castleBonus) {
                // no guarantee
                if(msg.sender.send(log.castleBonus ))
                    EventDestroyCastle(_castleId, msg.sender, true);
                else
                    EventDestroyCastle(_castleId, msg.sender, false);
            }
        }
        
        EventAttackCastle(msg.sender, _castleId, countWin>=2);
    }
    
}