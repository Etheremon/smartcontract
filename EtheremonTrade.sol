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

interface EtheremonBattleInterface {
    function isOnBattle(uint64 _objId) constant external returns(bool) ;
}

contract EtheremonTrade is EtheremonEnum, BasicAccessControl, SafeMath {
    
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
    
    // Gen0 has return price & no longer can be caught when this contract is deployed
    struct Gen0Config {
        uint32 classId;
        uint256 originalPrice;
        uint256 returnPrice;
        uint32 total; // total caught (not count those from eggs)
    }
    
    struct BorrowItem {
        uint index;
        address owner;
        address borrower;
        uint256 price;
        bool lent;
        uint releaseBlock;
    }
    
    struct SellingItem {
        uint index;
        uint256 price;
    }
    
    // data contract
    address public dataContract;
    address public battleContract;
    mapping(uint32 => Gen0Config) public gen0Config;
    
    // for selling
    mapping(uint64 => SellingItem) public sellingDict;
    uint32 public totalSellingItem;
    uint64[] public sellingList;
    
    // for borrowing
    mapping(uint64 => BorrowItem) public borrowingDict;
    uint32 public totalBorrowingItem;
    uint64[] public borrowingList;
    
    // trading fee
    uint16 public tradingFeeRatio = 100;
    
    modifier requireDataContract {
        require(dataContract != address(0));
        _;
    }
    
    modifier requireBattleContract {
        require(battleContract != address(0));
        _;
    }
    
    // event
    event EventPlaceSellOrder(address indexed seller, uint64 objId);
    event EventBuyItem(address indexed buyer, uint64 objId);
    event EventOfferBorrowingItem(address indexed lender, uint64 objId);
    event EventAcceptBorrowItem(address indexed borrower, uint64 objId);
    event EventGetBackItem(address indexed owner, uint64 objId);
    event EventFreeTransferItem(address indexed sender, address indexed receiver, uint64 objId);
    event EventRelease(address indexed trainer, uint64 objId);
    
    // constructor
    function EtheremonTrade(address _dataContract, address _battleContract) public {
        dataContract = _dataContract;
        battleContract = _battleContract;
    }
    
     // admin & moderators
    function setOriginalPriceGen0() onlyModerators public {
        gen0Config[1] = Gen0Config(1, 0.3 ether, 0.003 ether, 374);
        gen0Config[2] = Gen0Config(2, 0.3 ether, 0.003 ether, 408);
        gen0Config[3] = Gen0Config(3, 0.3 ether, 0.003 ether, 373);
        gen0Config[4] = Gen0Config(4, 0.2 ether, 0.002 ether, 437);
        gen0Config[5] = Gen0Config(5, 0.1 ether, 0.001 ether, 497);
        gen0Config[6] = Gen0Config(6, 0.3 ether, 0.003 ether, 380); 
        gen0Config[7] = Gen0Config(7, 0.2 ether, 0.002 ether, 345);
        gen0Config[8] = Gen0Config(8, 0.1 ether, 0.001 ether, 518); 
        gen0Config[9] = Gen0Config(9, 0.1 ether, 0.001 ether, 447);
        gen0Config[10] = Gen0Config(10, 0.2 ether, 0.002 ether, 380); 
        gen0Config[11] = Gen0Config(11, 0.2 ether, 0.002 ether, 354);
        gen0Config[12] = Gen0Config(12, 0.2 ether, 0.002 ether, 346);
        gen0Config[13] = Gen0Config(13, 0.2 ether, 0.002 ether, 351); 
        gen0Config[14] = Gen0Config(14, 0.2 ether, 0.002 ether, 338);
        gen0Config[15] = Gen0Config(15, 0.2 ether, 0.002 ether, 341);
        gen0Config[16] = Gen0Config(16, 0.35 ether, 0.0035 ether, 384);
        gen0Config[17] = Gen0Config(17, 1 ether, 0.01 ether, 305); 
        gen0Config[18] = Gen0Config(18, 0.1 ether, 0.001 ether, 427);
        gen0Config[19] = Gen0Config(19, 1 ether, 0.01 ether, 304);
        gen0Config[20] = Gen0Config(20, 0.4 ether, 0.05 ether, 82);
        gen0Config[21] = Gen0Config(21, 1, 1, 123);
        gen0Config[22] = Gen0Config(22, 0.2 ether, 0.001 ether, 468);
        gen0Config[23] = Gen0Config(23, 0.5 ether, 0.0025 ether, 302);
        gen0Config[24] = Gen0Config(24, 1 ether, 0.005 ether, 195);
    }
    
    function setContract(address _dataContract, address _battleContract) onlyModerators public {
        dataContract = _dataContract;
        battleContract = _battleContract;
    }
    
    function updateTradingFee(uint16 _fee) onlyModerators public {
        tradingFeeRatio = _fee;
    }
    
    function withdrawEther(address _sendTo, uint _amount) onlyModerators public {
        // no user money is kept in this contract, only trasaction fee
        if (_amount > this.balance) {
            revert();
        }
        _sendTo.transfer(_amount);
    }
    
    
    // helper
    function removeSellingItem(uint64 _itemId) private {
        SellingItem storage item = sellingDict[_itemId];
        if (item.index == 0)
            return;
        
        if (item.index <= sellingList.length) {
            // Move an existing element into the vacated key slot.
            sellingDict[sellingList[sellingList.length-1]].index = item.index;
            sellingList[item.index-1] = sellingList[sellingList.length-1];
            sellingList.length -= 1;
            delete sellingDict[_itemId];
        }
    }
    
    function addSellingItem(uint64 _itemId, uint256 _price) private {
        SellingItem storage item = sellingDict[_itemId];
        item.price = _price;
        
        if (item.index == 0) {
            item.index = ++sellingList.length;
            sellingList[item.index - 1] = _itemId;
        }
    }

    function removeBorrowingItem(uint64 _itemId) private {
        BorrowItem storage item = borrowingDict[_itemId];
        if (item.index == 0)
            return;
        
        if (item.index <= borrowingList.length) {
            // Move an existing element into the vacated key slot.
            borrowingDict[borrowingList[borrowingList.length-1]].index = item.index;
            borrowingList[item.index-1] = borrowingList[borrowingList.length-1];
            borrowingList.length -= 1;
            delete borrowingDict[_itemId];
        }
    }

    function addBorrowingItem(address _owner, uint64 _itemId, uint256 _price, uint blockCount) private {
        BorrowItem storage item = borrowingDict[_itemId];
        item.owner = _owner;
        item.borrower = address(0);
        item.price = _price;
        item.lent = false;
        item.releaseBlock = blockCount;
        
        if (item.index == 0) {
            item.index = ++borrowingList.length;
            borrowingList[item.index - 1] = _itemId;
        }
    }
    
    function transferMonster(address _to, uint64 _objId) private {
        EtheremonDataBase data = EtheremonDataBase(dataContract);

        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(_objId);

        // clear balance for gen 0
        if (obj.classId <= GEN0_NO) {
            Gen0Config storage gen0 = gen0Config[obj.classId];
            if (gen0.classId == obj.classId) {
                if (obj.lastClaimIndex < gen0.total) {
                    uint32 gap = uint32(safeSubtract(gen0.total, obj.lastClaimIndex));
                    if (gap > 0) {
                        data.addExtraBalance(obj.trainer, safeMult(gap, gen0.returnPrice));
                        // reset total (accept name is cleared :( )
                        data.setMonsterObj(obj.monsterId, " name me ", obj.exp, obj.createIndex, gen0.total);
                    }
                }
            }
        }
        
        // transfer owner
        data.removeMonsterIdMapping(obj.trainer, _objId);
        data.addMonsterIdMapping(_to, _objId);
    }
    
    // public
    function placeSellOrder(uint64 _objId, uint256 _price) requireDataContract requireBattleContract isActive external {
        // not on selling
        if (sellingDict[_objId].index > 0 || _price == 0)
            revert();
        // not on borrowing
        BorrowItem storage item = borrowingDict[_objId];
        if (item.index > 0)
            revert();
        // not on battle 
        EtheremonBattleInterface battle = EtheremonBattleInterface(battleContract);
        if (battle.isOnBattle(_objId))
            revert();
        
        // check ownership
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        uint32 _ = 0;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, _, _, obj.createTime) = data.getMonsterObj(_objId);
        
        if (obj.monsterId != _objId) {
            revert();
        }
        
        if (obj.trainer != msg.sender) {
            revert();
        }
        
        addSellingItem(_objId, _price);
        EventPlaceSellOrder(msg.sender, _objId);
    }
    
    function removeSellOrder(uint64 _objId) requireDataContract requireBattleContract isActive external {
        if (sellingDict[_objId].index == 0)
            revert();
        
        // check ownership
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        uint32 _ = 0;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, _, _, obj.createTime) = data.getMonsterObj(_objId);
        
        if (obj.monsterId != _objId) {
            revert();
        }
        
        if (obj.trainer != msg.sender) {
            revert();
        }
        
        removeSellingItem(_objId);
    }
    
    function buyItem(uint64 _objId) requireDataContract requireBattleContract isActive external payable {
        // check item is valid to sell 
        uint256 requestPrice = sellingDict[_objId].price;
        if (requestPrice == 0 || msg.value < requestPrice) {
            revert();
        }
        
        // check obj
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        uint32 _ = 0;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, _, _, obj.createTime) = data.getMonsterObj(_objId);
        if (obj.monsterId != _objId) {
            revert();
        }
        
        address oldTrainer = obj.trainer;
        uint256 fee = requestPrice / tradingFeeRatio;
        removeSellingItem(_objId);
        transferMonster(msg.sender, _objId);
        oldTrainer.transfer(safeSubtract(requestPrice, fee));
        EventBuyItem(msg.sender, _objId);
    }
    
    function offerBorrowingItem(uint64 _objId, uint256 _price, uint _blockCount) requireDataContract requireBattleContract isActive external {
        // make sure it is not on sale 
        if (sellingDict[_objId].price > 0 || _price == 0)
            revert();
        // not on borrowing
        BorrowItem storage item = borrowingDict[_objId];
        if (item.index > 0)
            revert();
        // not on battle 
        EtheremonBattleInterface battle = EtheremonBattleInterface(battleContract);
        if (battle.isOnBattle(_objId))
            revert();
        
        
        // check ownership
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        uint32 _ = 0;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, _, _, obj.createTime) = data.getMonsterObj(_objId);
        
        if (obj.monsterId != _objId) {
            revert();
        }
        
        if (obj.trainer != msg.sender) {
            revert();
        }
        
        addBorrowingItem(msg.sender, _objId, _price, _blockCount);
        EventOfferBorrowingItem(msg.sender, _objId);
    }
    
    function removeBorrowingOfferItem(uint64 _objId) requireDataContract requireBattleContract isActive external {
        BorrowItem storage item = borrowingDict[_objId];
        if (item.index == 0)
            revert();
        
        if (item.owner != msg.sender)
            revert();
        if (item.lent == true)
            revert();
        
        removeBorrowingItem(_objId);
    }
    
    function borrowItem(uint64 _objId) requireDataContract requireBattleContract isActive external payable {
        BorrowItem storage item = borrowingDict[_objId];
        if (item.index == 0)
            revert();
        if (item.lent == true)
            revert();
        uint256 itemPrice = item.price;
        if (itemPrice > msg.value)
            revert();
        

        // check obj
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        uint32 _ = 0;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, _, _, obj.createTime) = data.getMonsterObj(_objId);
        if (obj.monsterId != _objId) {
            revert();
        }
        
        uint256 fee = itemPrice/tradingFeeRatio;
        item.borrower = msg.sender;
        item.releaseBlock += block.number;
        item.lent = true;
        address oldOwner = obj.trainer;
        transferMonster(msg.sender, _objId);
        oldOwner.transfer(safeSubtract(itemPrice, fee));
        EventAcceptBorrowItem(msg.sender, _objId);
    }
    
    function getBackLendingItem(uint64 _objId) requireDataContract requireBattleContract isActive external {
        BorrowItem storage item = borrowingDict[_objId];
        if (item.index == 0)
            revert();
        if (item.lent == false)
            revert();
        if (item.releaseBlock > block.number)
            revert();
        
        if (msg.sender != item.owner)
            revert();
        
        removeBorrowingItem(_objId);
        transferMonster(msg.sender, _objId);
        EventGetBackItem(msg.sender, _objId);
    }
    
    function freeTransferItem(uint64 _objId, address _receiver) requireDataContract requireBattleContract external {
        // make sure it is not on sale 
        if (sellingDict[_objId].price > 0)
            revert();
        // not on borrowing
        BorrowItem storage item = borrowingDict[_objId];
        if (item.index > 0)
            revert();
        // not on battle 
        EtheremonBattleInterface battle = EtheremonBattleInterface(battleContract);
        if (battle.isOnBattle(_objId))
            revert();
        
        // check ownership
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        uint32 _ = 0;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, _, _, obj.createTime) = data.getMonsterObj(_objId);
        
        if (obj.monsterId != _objId) {
            revert();
        }
        
        if (obj.trainer != msg.sender) {
            revert();
        }
        
        transferMonster(_receiver, _objId);
        EventFreeTransferItem(msg.sender, _receiver, _objId);
    }
    
    function release(uint64 _objId) requireDataContract requireBattleContract external {
        // make sure it is not on sale 
        if (sellingDict[_objId].price > 0)
            revert();
        // not on borrowing
        BorrowItem storage item = borrowingDict[_objId];
        if (item.index > 0)
            revert();
        // not on battle 
        EtheremonBattleInterface battle = EtheremonBattleInterface(battleContract);
        if (battle.isOnBattle(_objId))
            revert();
        
        // check ownership
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        uint32 _ = 0;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, _, _, obj.createTime) = data.getMonsterObj(_objId);
        
        // can not release gen 0
        if (obj.classId <= GEN0_NO) {
            revert();
        }
        
        if (obj.monsterId != _objId) {
            revert();
        }
        
        if (obj.trainer != msg.sender) {
            revert();
        }
        
        data.removeMonsterIdMapping(msg.sender, _objId);
        EventRelease(msg.sender, _objId);
    }
    
    // read access
    
    function getTotalSellingItem() constant external returns(uint) {
        return sellingList.length;
    }

    function getSellingItemId(uint _index) constant external returns(uint64) {
        return sellingList[_index];
    }
    
    function getSellingItemPrice(uint64 _itemId) constant external returns(uint256) {
        return sellingDict[_itemId].price;
    }

    function getTotalBorrowingItem() constant external returns(uint) {
        return borrowingList.length;
    }

    function getBorrowingItemId(uint _index) constant external returns(uint64) {
        return borrowingList[_index];
    }
    
    function getBorrowingInfoPrice(uint64 _itemId) constant external returns(uint index, address owner, address borrower, 
        uint256 price, bool lent, uint releaseBlock) {
        BorrowItem storage item = borrowingDict[_itemId];
        index = item.index;
        owner = item.owner;
        borrower = item.borrower;
        price = item.price;
        lent = item.lent;
        releaseBlock = item.releaseBlock;
    }
    
    function isOnTrading(uint64 _objId) constant external returns(bool) {
        return (sellingDict[_objId].price > 0 || borrowingDict[_objId].owner != address(0));
    }
}