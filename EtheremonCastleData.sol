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

contract EtheremonCastleBattle is BasicAccessControl, SafeMath {
    uint8 constant public NO_MONSTER = 3;
    uint8 constant public NO_BATTLE_LOG = 5;
    
    struct CastleData {
        uint index; // in active castle if > 0
        uint32 castleId;
        string name;
        address owner;
        uint32 totalWin;
        uint32 totalLose;
        uint64[3] attackers;
        uint64[3] supporters;
        uint64[5] battleList;
        uint256 price;
        uint32 minBattle;
        uint lastListIndex;
        uint createdBlock;
    }
    
    struct MonsterBattleLog {
        uint64 objId;
        uint32 exp;
    }
    
    struct BattleDataLog {
        uint32 castleId;
        address attacker;
        MonsterBattleLog[12] etheremons;
        uint8[3] randoms;
        bool win;
    }
    
    struct TrainerBattleLog {
        uint32 totalCastle;
        uint32 totalWin;
        uint32 totalLose;
        uint64[5] battleList;
        uint lastListIndex;
    }
    
    mapping(uint64 => BattleDataLog) battles;
    mapping(address => uint32) trainerCastle;
    mapping(address => TrainerBattleLog) trannerBattleLog;
    mapping(uint32 => CastleData) castleData;
    uint32[] activeCastleList;

    uint32 public totalCastle = 0;
    uint64 public totalBattle = 0;
    
    // only moderators
    /*
    TO AVOID ANY BUGS, WE ALLOW MODERATORS TO HAVE PERMISSION TO ALL THESE FUNCTIONS AND UPDATE THEM IN EARLY BETA STAGE.
    AFTER THE SYSTEM IS STABLE, WE WILL REMOVE OWNER OF THIS SMART CONTRACT AND ONLY KEEP ONE MODERATOR WHICH IS ETHEREMON BATTLE CONTRACT.
    HENCE, THE DECENTRALIZED ATTRIBUTION IS GUARANTEED.
    */
    
    function setCastle(address _trainer, string _name, uint64 _a1, uint64 _a2, uint64 _a3, uint64 _s1, uint64 _s2, uint64 _s3) onlyModerators external returns(uint32 currentCastleId){
        currentCastleId = trainerCastle[_trainer];
        uint index;
        if (currentCastleId == 0) {
            // create a new castle
            totalCastle += 1;
            currentCastleId = totalCastle;
            
            index = ++activeCastleList.length;
            activeCastleList[index-1] = currentCastleId;
            // mark sender
            trainerCastle[_trainer] = currentCastleId;
            trannerBattleLog[_trainer].totalCastle += 1;
        }
        CastleData storage castle = castleData[currentCastleId];
        castle.index = index;
        castle.castleId = currentCastleId;
        castle.name = _name;
        castle.owner = _trainer;
        castle.attackers[0] = _a1;
        castle.attackers[1] = _a2;
        castle.attackers[2] = _a3;
        castle.supporters[0] = _s1;
        castle.supporters[1] = _s2;
        castle.supporters[2] = _s3;
        castle.createdBlock = block.number;
    }
    
    function setCastlePrice(uint32 _castleId, uint256 _price, uint32 _minBattle) onlyModerators external {
        CastleData storage castle = castleData[_castleId];
        castle.price = _price;
        castle.minBattle = _minBattle;
    }
    
    function removeCastleFromActive(uint32 _castleId) onlyModerators external {
        CastleData storage castle = castleData[_castleId];
        if (castle.index == 0)
            return;
        
        trainerCastle[castle.owner] = 0;
        if (castle.index <= activeCastleList.length) {
            // Move an existing element into the vacated key slot.
            castleData[activeCastleList[activeCastleList.length-1]].index = castle.index;
            activeCastleList[castle.index-1] = activeCastleList[activeCastleList.length-1];
            activeCastleList.length -= 1;
            castle.index = 0;
        }
    }
    
    function addBattleLog(uint32 _castleId, address _attacker, uint8 _ran1, uint8 _ran2, uint8 _ran3, bool _win) onlyModerators external returns(uint64) {
        totalBattle += 1;
        BattleDataLog storage battleLog = battles[totalBattle];
        battleLog.castleId = _castleId;
        battleLog.attacker = _attacker;
        battleLog.randoms[0] = _ran1;
        battleLog.randoms[1] = _ran2;
        battleLog.randoms[2] = _ran3;
        battleLog.win = _win;
        
        CastleData storage castle = castleData[_castleId];
        TrainerBattleLog storage trainerLog = trannerBattleLog[_attacker];
        if (_win) {
            castle.totalWin += 1;
            trainerLog.totalLose += 1;
        } else {
            castle.totalLose += 1;
            trainerLog.totalLose += 1;
        }
        
        castle.lastListIndex += 1;
        if (castle.lastListIndex >= NO_BATTLE_LOG) {
            castle.lastListIndex = 0;
        }
        castle.battleList[castle.lastListIndex] = totalBattle;
        
        trainerLog.lastListIndex += 1;
        if (trainerLog.lastListIndex >= NO_BATTLE_LOG) {
            trainerLog.lastListIndex = 0;
        }
        trainerLog.battleList[trainerLog.lastListIndex] = totalBattle;
        
        return totalBattle;
    }
    
    function addBattleMonsterLog(uint64 _battleId, uint64 _objId, uint32 _exp, uint _index) onlyModerators external {
        BattleDataLog storage battleLog = battles[_battleId];
        battleLog.etheremons[_index].objId = _objId;
        battleLog.etheremons[_index].exp = _exp;
    }
    
    // read access 
    function isCastleActive(uint32 _castleId) constant external returns(bool){
        CastleData storage castle = castleData[_castleId];
        return (castle.index > 0);
    }
    
    function countActiveCastle() constant external returns(uint) {
        return activeCastleList.length;
    }
    
    function getActiveCastleId(uint index) constant external returns(uint32) {
        return activeCastleList[index];
    }
    
    function getCastleBasicInfo(address _owner) constant external returns(uint32, uint) {
        uint32 currentCastleId = trainerCastle[_owner];
        if (currentCastleId == 0)
            return (0, 0);
        CastleData memory castle = castleData[currentCastleId];
        return (castle.castleId, castle.index);
    }
    
    function getCastleBasicInfoById(uint32 _castleId) constant external returns(uint, address) {
        CastleData memory castle = castleData[_castleId];
        return (castle.index, castle.owner);
    }
    
    function getCastleObjInfo(uint32 _castleId) constant external returns(uint64, uint64, uint64, uint64, uint64, uint64) {
        CastleData memory castle = castleData[_castleId];
        return (castle.attackers[0], castle.attackers[1], castle.attackers[2], castle.supporters[0], castle.supporters[1], castle.supporters[2]);
    }
    
    function getCastleWinLose(uint32 _castleId) constant external returns(uint32, uint32, uint256, uint32) {
        CastleData memory castle = castleData[_castleId];
        return (castle.totalWin, castle.totalLose, castle.price, castle.minBattle);
    }
    
    function getCastleStats(uint32 _castleId) constant external returns(string, address, uint256, uint32, uint32, uint32, uint) {
        CastleData memory castle = castleData[_castleId];
        return (castle.name, castle.owner, castle.price, castle.minBattle, castle.totalWin, castle.totalLose, castle.createdBlock);
    }

    function getBattleDataLog(uint64 _matchId) constant external returns(uint32, address, uint8, uint8, uint8, bool) {
        BattleDataLog memory battleLog = battles[_matchId];
        return (battleLog.castleId, battleLog.attacker, battleLog.randoms[0], battleLog.randoms[1], battleLog.randoms[2], battleLog.win);
    }
    
    function getBattleMonsterLog(uint64 _matchId, uint _index) constant external returns(uint64, uint32) {
        BattleDataLog memory battleLog = battles[_matchId];
        return (battleLog.etheremons[_index].objId, battleLog.etheremons[_index].exp);
    }
    
    function getCastleBattleList(uint32 _castleId) constant external returns(uint64, uint64, uint64, uint64, uint64) {
        CastleData storage castle = castleData[_castleId];
        return (castle.battleList[0], castle.battleList[1], castle.battleList[2], castle.battleList[3], castle.battleList[4]);
    }
    
    function getTrainerBattleInfo(address _trainer) constant external returns(uint32, uint32, uint32, uint64, uint64, uint64, uint64, uint64) {
        TrainerBattleLog memory trainerLog = trannerBattleLog[_trainer];
        return (trainerLog.totalWin, trainerLog.totalLose, trainerLog.totalCastle, trainerLog.battleList[0], trainerLog.battleList[1], trainerLog.battleList[2], 
            trainerLog.battleList[3], trainerLog.battleList[4]);
    }
    
    function isOnCastle(uint32 _castleId, uint64 _objId) constant external returns(bool) {
        CastleData storage castle = castleData[_castleId];
        if (castle.index > 0) {
            if (castle.attackers[0] == _objId || castle.attackers[1] == _objId || castle.attackers[2] == _objId)
                return true;
            if (castle.supporters[0] == _objId || castle.supporters[1] == _objId || castle.supporters[2] == _objId)
                return true;
        }
        return false;
    }
}