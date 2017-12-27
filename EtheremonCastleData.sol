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
        require(moderators[msg.sender] == true);
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
        ERROR_INVALID_AMOUNT
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

contract EtheremonCastleBattle is BasicAccessControl, SafeMath {
    uint8 constant public NO_MONSTER = 3;
    uint8 constant public NO_BATTLE_LOG = 5;
    
    struct CastleData {
        uint index; // in active castle if it is active
        uint32 castleId;
        string name;
        address owner;
        uint16 totalWin;
        uint16 totalLoose;
        uint64[NO_MONSTER] attackers;
        uint64[NO_MONSTER] supporters;
        uint64[NO_BATTLE_LOG] battleList;
        uint lastListIndex;
        uint createdBlock;
    }
    
    struct MonsterBattleLog {
        uint64 objId;
        uint32 exp;
    }
    
    struct MatchDataLog {
        uint32 castleId;
        address attacker;
        MonsterBattleLog[NO_MONSTER*4] etheremons;
        uint8[NO_MONSTER] randoms;
        bool win;
    }
    
    mapping(uint64 => MatchDataLog) matches;
    mapping(address => uint32) trainerCastle;
    mapping(address => uint64[NO_BATTLE_LOG]) trannerBattleLog;
    mapping(uint32 => CastleData) castleData;
    uint32[] activeCastleList;

    uint32 public totalCastle = 0;
    uint64 public totalMatches = 0;

    // private
    function removeCastleFromActive(uint32 _castleId) private {
        CastleData storage castle = castleData[_castleId];
        if (castle.index == 0)
            return;
        
        if (castle.index <= activeCastleList.length) {
            // Move an existing element into the vacated key slot.
            castleData[activeCastleList[activeCastleList.length-1]].index = castle.index;
            activeCastleList[castle.index-1] = activeCastleList[activeCastleList.length-1];
            activeCastleList.length -= 1;
            castle.index = 0;
        }
    }

    
    // only moderators
    /*
    TO AVOID ANY BUGS, WE ALLOW MODERATORS TO HAVE PERMISSION TO ALL THESE FUNCTIONS AND UPDATE THEM IN EARLY BETA STAGE.
    AFTER THE SYSTEM IS STABLE, WE WILL REMOVE OWNER OF THIS SMART CONTRACT AND ONLY KEEP ONE MODERATOR.
    HENCE, THE DECENTRALIZED ATTRIBUTION IS GUARANTEED.
    */
    
    function setCastle(address _trainer, string _name, uint64 _a1, uint64 _a2, uint64 _a3, uint64 _s1, uint64 _s2, uint64 _s3) onlyModerators external returns(uint32){
        uint32 currentCastleId = trainerCastle[_trainer];
        CastleData storage castle = castleData[currentCastleId];
        if (currentCastleId == 0) {
            totalCastle += 1;
            currentCastleId = totalCastle;
            
            castle.index = ++activeCastleList.length;
            activeCastleList[castle.index-1] = currentCastleId;
            // mark sender
            trainerCastle[msg.sender] = currentCastleId;
        }
        
        castle.castleId = currentCastleId;
        castle.name = _name;
        castle.owner = msg.sender;
        castle.attackers[0] = _a1;
        castle.attackers[1] = _a2;
        castle.attackers[2] = _a3;
        castle.supporters[0] = _s1;
        castle.supporters[1] = _s2;
        castle.supporters[2] = _s3;
        castle.createdBlock = block.number;
        return castle.castleId;
    }
    
    function removeCastle(uint32 _castleId) onlyModerators external {
        CastleData storage castle = castleData[_castleId];
        if (castle.owner != msg.sender)
            revert();
        removeCastleFromActive(_castleId);
    }
    
    function addBattleLog(uint32 _castleId, address _attacker, uint8 _ran1, uint8 _ran2, uint8 _ran3, bool _win) onlyModerators external returns(uint64) {
        totalMatches += 1;
        MatchDataLog storage matchLog = matches[totalMatches];
        matchLog.castleId = _castleId;
        matchLog.attacker = _attacker;
        matchLog.randoms[0] = _ran1;
        matchLog.randoms[1] = _ran2;
        matchLog.randoms[2] = _ran3;
        matchLog.win = _win;
        
        CastleData storage castle = castleData[_castleId];
        if (_win)
            castle.totalWin += 1;
        else
            castle.totalLoose += 1;
        
        castle.lastListIndex += 1;
        if (castle.lastListIndex >= NO_BATTLE_LOG) {
            castle.lastListIndex = 0;
        }
        castle.battleList[castle.lastListIndex] = totalMatches;
        
        uint minIndex = 0;
        for (uint i=0; i < trannerBattleLog[_attacker].length; i++) {
            if (trannerBattleLog[_attacker][i] <  trannerBattleLog[_attacker][minIndex])
                minIndex = i;
        }
        trannerBattleLog[_attacker][minIndex] = totalMatches;
        
        return totalMatches;
    }
    
    function addBattleMonsterLog(uint64 _matchId, uint64 _objId, uint32 _exp, uint _index) onlyModerators external {
        MatchDataLog storage matchLog = matches[_matchId];
        matchLog.etheremons[_index].objId = _objId;
        matchLog.etheremons[_index].exp = _exp;
    }
    
    // read access 
    function isCastleActive(uint32 _castleId) constant external returns(bool){
        CastleData storage castle = castleData[_castleId];
        return (castle.index > 0);
    }
    
    function countActiveCastle() constant external returns(uint) {
        return activeCastleList.length;
    }
    
    function getCastleBasicInfo(address owner) constant external returns(uint32, uint) {
        uint32 currentCastleId = trainerCastle[owner];
        if (currentCastleId == 0)
            return (0, 0);
        CastleData memory castle = castleData[currentCastleId];
        return (castle.castleId, castle.index);
    }
    
    function getCastleBasicInfoById(uint32 _castleId) constant external returns(uint32, uint) {
        CastleData memory castle = castleData[_castleId];
        return (castle.castleId, castle.index);
    }
    
    function getCastleObjInfo(uint32 _castleId) constant external returns(uint64, uint64, uint64, uint64, uint64, uint64) {
        CastleData memory castle = castleData[_castleId];
        return (castle.attackers[0], castle.attackers[1], castle.attackers[2], castle.supporters[0], castle.supporters[1], castle.supporters[2]);
    }
    
    function getCastleWinLoose(uint32 _castleId) constant external returns(uint16, uint16) {
        CastleData memory castle = castleData[_castleId];
        return (castle.totalWin, castle.totalLoose);
    }
    
    function getCastleStats(uint32 _castleId) constant external returns(string, address, uint16, uint16, uint) {
        CastleData memory castle = castleData[_castleId];
        return (castle.name, castle.owner, castle.totalWin, castle.totalLoose, castle.createdBlock);
    }

    function getMatchDataLog(uint64 _matchId) constant external returns(uint32, address, uint8, uint8, uint8, bool) {
        MatchDataLog memory matchLog = matches[_matchId];
        return (matchLog.castleId, matchLog.attacker, matchLog.randoms[0], matchLog.randoms[1], matchLog.randoms[2], matchLog.win);
    }
    
    function getMatchMonsterLog(uint64 _matchId, uint _index) constant external returns(uint64, uint32) {
        MatchDataLog memory matchLog = matches[_matchId];
        return (matchLog.etheremons[_index].objId, matchLog.etheremons[_index].exp);
    }
    
    function getCastleBattleList(uint32 _castleId) constant external returns(uint64, uint64, uint64, uint64, uint64) {
        CastleData storage castle = castleData[_castleId];
        return (castle.battleList[0], castle.battleList[1], castle.battleList[2], castle.battleList[3], castle.battleList[4]);
    }
    
    function getTrainerBattleList(address _trainer) constant external returns(uint64, uint64, uint64, uint64, uint64) {
        uint64[NO_BATTLE_LOG] memory log = trannerBattleLog[_trainer];
        return (log[0], log[1], log[2], log[3], log[4]);
    }
}