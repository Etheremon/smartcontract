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
    address[] public moderators;
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
            bool found = false;
            for (uint index = 0; index < moderators.length; index++) {
                if (moderators[index] == msg.sender) {
                    found = true;
                    break;
                }
            }
            require(found);
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
        if (_newModerator != address(0)) {
            for (uint index = 0; index < moderators.length; index++) {
                if (moderators[index] == _newModerator) {
                    return;
                }
            }
            moderators.push(_newModerator);
        }
    }
    
    function RemoveModerator(address _oldModerator) onlyOwner public {
        uint foundIndex = 0;
        for (; foundIndex < moderators.length; foundIndex++) {
            if (moderators[foundIndex] == _oldModerator) {
                break;
            }
        }
        if (foundIndex < moderators.length) {
            moderators[foundIndex] = moderators[moderators.length-1];
            delete moderators[moderators.length-1];
            moderators.length--;
        }
    }

    function updateMaintenance(bool _isMaintaining) onlyModerators public {
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
        uint64 objId;
        address owner;
        address borrower;
        uint256 price;
        bool lent;
        uint releaseBlock;
    }
    
    // data contract
    address public dataContract;
    address public worldContract;
    mapping(uint32 => Gen0Config) public gen0Config;
    
    // for selling
    mapping(uint64 => uint256) public sellingDict;
    uint64[] public sellingList;
    
    // for borrowing
    mapping(uint64 => BorrowItem) public borrowingDict;
    mapping(address => uint64[]) public onLendingByTrainer;
    uint64[] public borrowingList;
    
    // trading fee
    uint16 public tradingFeeRatio = 100;
    
    modifier requireDataContract {
        require(dataContract != 0x0);
        _;
    }
    
    modifier requireWorldContract {
        require(worldContract != 0x0);
        _;
    }
    
    // event
    event EventPlaceSellOrder(address indexed seller, uint64 objId);
    event EventBuyItem(address indexed buyer, uint64 objId);
    event EventOfferBorrowingItem(address indexed lender, uint64 objId);
    event EventAccepBorrowItem(address indexed borrower, uint64 objId);
    
    // constructor
    function EtheremonTrade(address _dataContract) public {
        dataContract = _dataContract;
    }
    
     // admin & moderators
    function setOriginalPriceGen0() onlyModerators public {
        gen0Config[1] = Gen0Config(1, 300000000000000000, 3000000000000000, 374);
        gen0Config[2] = Gen0Config(2, 300000000000000000, 3000000000000000, 408);
        gen0Config[3] = Gen0Config(3, 300000000000000000, 3000000000000000, 373);
        gen0Config[4] = Gen0Config(4, 200000000000000000, 2000000000000000, 437);
        gen0Config[5] = Gen0Config(5, 100000000000000000, 1000000000000000, 497);
        gen0Config[6] = Gen0Config(6, 300000000000000000, 3000000000000000, 380); 
        gen0Config[7] = Gen0Config(7, 200000000000000000, 2000000000000000, 345);
        gen0Config[8] = Gen0Config(8, 100000000000000000, 1000000000000000, 518); 
        gen0Config[9] = Gen0Config(9, 100000000000000000, 1000000000000000, 447);
        gen0Config[10] = Gen0Config(10, 200000000000000000, 2000000000000000, 380); 
        gen0Config[11] = Gen0Config(11, 200000000000000000, 2000000000000000, 354);
        gen0Config[12] = Gen0Config(12, 200000000000000000, 2000000000000000, 346);
        gen0Config[13] = Gen0Config(13, 200000000000000000, 2000000000000000, 351); 
        gen0Config[14] = Gen0Config(14, 200000000000000000, 2000000000000000, 338);
        gen0Config[15] = Gen0Config(15, 200000000000000000, 2000000000000000, 341);
        gen0Config[16] = Gen0Config(16, 350000000000000000, 3500000000000000, 384);
        gen0Config[17] = Gen0Config(17, 1000000000000000000, 10000000000000000, 305); 
        gen0Config[18] = Gen0Config(18, 100000000000000000, 1000000000000000, 427);
        gen0Config[19] = Gen0Config(19, 1000000000000000000, 10000000000000000, 304);
        gen0Config[20] = Gen0Config(20, 400000000000000000, 50000000000000000, 82);
        gen0Config[21] = Gen0Config(21, 1, 1, 123);
        gen0Config[22] = Gen0Config(22, 200000000000000000, 1000000000000000, 468);
        gen0Config[23] = Gen0Config(23, 500000000000000000, 2500000000000000, 302);
        gen0Config[24] = Gen0Config(24, 1000000000000000000, 5000000000000000, 195);
    }
     
    function setContract(address _dataContract) onlyModerators public {
        dataContract = _dataContract;
    }
    
    function updateTradingFee(uint16 _fee) onlyModerators public {
        tradingFeeRatio = _fee;
    }
    
    function updateWorldContract(address _worldContract) onlyModerators public {
        worldContract = _worldContract;
    }
    
    function withdrawEther(address _sendTo, uint _amount) onlyModerators public returns(ResultCode) {
        // no user money is kept in this contract, only trasaction fee
        if (_amount > this.balance) {
            revert();
        }
        _sendTo.transfer(_amount);
    }
    
    
    // helper
    function removeSellingItem(uint64 _itemId) private {
        sellingDict[_itemId] = 0;
        // remove from the list;
        uint foundIndex = 0;
        for (; foundIndex < sellingList.length; foundIndex++) {
            if (sellingList[foundIndex] == _itemId) {
                break;
            }
        }
        if (foundIndex < sellingList.length) {
            sellingList[foundIndex] = sellingList[sellingList.length-1];
            delete sellingList[sellingList.length-1];
            sellingList.length--;
        }
    }
    
    function addSellingItem(uint64 _itemId, uint256 _price) private {
        sellingDict[_itemId] = _price;

        for (uint i = 0; i < sellingList.length; i++) {
            if (sellingList[i] == _itemId) {
                return;
            }
        }
        sellingList.push(_itemId);
    }

    function removeBorrowingItem(uint64 _itemId) private {
        BorrowItem storage item = borrowingDict[_itemId];
        item.objId = 0;
        item.owner = 0x0;
        item.borrower = 0x0;
        item.price = 0;
        item.lent = false;
        item.releaseBlock = 0;
        
        // remove from the list;
        uint foundIndex = 0;
        for (; foundIndex < borrowingList.length; foundIndex++) {
            if (borrowingList[foundIndex] == _itemId) {
                break;
            }
        }
        if (foundIndex < borrowingList.length) {
            borrowingList[foundIndex] = borrowingList[borrowingList.length-1];
            delete borrowingList[borrowingList.length-1];
            borrowingList.length--;
        }
    }

    function addBorrowingItem(address _owner, uint64 _itemId, uint256 _price, uint blockCount) private {
        BorrowItem storage item = borrowingDict[_itemId];
        item.objId = _itemId;
        item.owner = _owner;
        item.borrower = 0x0;
        item.price = _price;
        item.lent = false;
        item.releaseBlock = blockCount;
        
        for (uint i = 0; i < borrowingList.length; i++) {
            if (borrowingList[i] == _itemId) {
                return;
            }
        }
        borrowingList.push(_itemId);
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
    
    function placeSellOrder(uint64 _objId, uint256 _price) requireDataContract isActive public {
        // not on selling
        if (sellingDict[_objId] > 0)
            revert();
        // not on borrowing
        BorrowItem storage item = borrowingDict[_objId];
        if (item.objId == _objId)
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
    
    function removeSellOrder(uint64 _objId) requireDataContract isActive public {
        if (sellingDict[_objId] == 0)
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
    
    function buyItem(uint64 _objId, uint256 _buyingPrice) requireDataContract isActive public payable returns(ResultCode) {
        // check item is valid to sell 
        uint256 requestPrice = sellingDict[_objId];
        if (requestPrice == 0 || requestPrice != _buyingPrice) {
            revert();
        }
        
        // check obj
        MonsterObjAcc memory obj;
        uint32 _ = 0;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, _, _, obj.createTime) = data.getMonsterObj(_objId);
        
        if (obj.monsterId != _objId) {
            revert();
        }
        
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        // check buyer has enough money
        uint256 totalBalance = safeAdd(msg.value, data.getExtraBalance(msg.sender));
        if (totalBalance < requestPrice) {
            revert();
        }
        
        uint256 deductedAmount = totalBalance - requestPrice;
        data.setExtraBalance(msg.sender, deductedAmount);
        transferMonster(msg.sender, _objId);
        data.addExtraBalance(obj.trainer, safeSubtract(requestPrice, requestPrice / tradingFeeRatio));
        
        // send money to etheremon world contract
        worldContract.transfer(safeSubtract(requestPrice, requestPrice / tradingFeeRatio));
        
        EventBuyItem(msg.sender, _objId);
    }
    
    function offerBorrowingItem(uint64 _objId, uint256 _price, uint _blockCount) requireDataContract isActive public {
        // make sure it is not on sale 
        if (sellingDict[_objId] > 0)
            revert();
        // not on borrowing
        BorrowItem storage item = borrowingDict[_objId];
        if (item.objId == _objId)
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
    
    function removeBorrowingOfferItem(uint64 _objId) requireDataContract isActive public {
        BorrowItem storage item = borrowingDict[_objId];
        if (item.objId != _objId)
            revert();
        
        if (item.owner != msg.sender)
            revert();
        if (item.lent == true)
            revert();
        
        removeBorrowingItem(_objId);
    }
    
    function borrowItem(uint64 _objId, uint256 _price) requireDataContract isActive public payable {
        BorrowItem storage item = borrowingDict[_objId];
        if (item.objId != _objId)
            revert();
        if (item.lent == true)
            revert();
        if (item.price != _price)
            revert();
        

        // check obj
        MonsterObjAcc memory obj;
        uint32 _ = 0;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, _, _, obj.createTime) = data.getMonsterObj(_objId);
        
        if (obj.monsterId != _objId) {
            revert();
        }
        
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        // check buyer has enough money
        uint256 totalBalance = safeAdd(msg.value, data.getExtraBalance(msg.sender));
        if (totalBalance < item.price) {
            revert();
        }
        
        uint256 deductedAmount = totalBalance - item.price;

        data.setExtraBalance(msg.sender, deductedAmount);
        item.borrower = msg.sender;
        item.releaseBlock += block.number;
        item.lent = true;
        transferMonster(msg.sender, _objId);
        data.addExtraBalance(obj.trainer, safeSubtract(item.price, item.price/tradingFeeRatio));
        
        // send to world contract 
        worldContract.transfer(safeSubtract(item.price, item.price/tradingFeeRatio));
        
        EventBuyItem(msg.sender, _objId);
        
    }
    
    function getBackLendingItem(uint64 _objId) requireDataContract isActive public {
        BorrowItem storage item = borrowingDict[_objId];
        if (item.objId != _objId)
            revert();
        if (item.lent == false)
            revert();
        if (item.releaseBlock > block.number)
            revert();
        
        if (msg.sender != item.owner)
            revert();
        
        transferMonster(msg.sender, _objId);
        removeBorrowingItem(_objId);
    }
    
    function freeTransferItem(uint64 _objId, address _receiver) requireDataContract isActive public {
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
    }
    
    // read access
    
    function getTotalSellingItem() constant public returns(uint) {
        return sellingList.length;
    }

    function getSellingItemId(uint _index) constant public returns(uint64) {
        return sellingList[_index];
    }
    
    function getSellingItemPrice(uint64 _itemId) constant public returns(uint256) {
        return sellingList[_itemId];
    }

    function getTotalBorrowingItem() constant public returns(uint) {
        return borrowingList.length;
    }

    function getBorrowingItemId(uint _index) constant public returns(uint64) {
        return borrowingList[_index];
    }
    
    function getBorrowingInfoPrice(uint64 _itemId) constant public returns(uint64 objId, address owner, address borrower, 
        uint256 price, bool lent, uint releaseBlock) {
        BorrowItem storage item = borrowingDict[_itemId];
        objId = item.objId;
        owner = item.owner;
        borrower = item.borrower;
        price = item.price;
        lent = item.lent;
        releaseBlock = item.releaseBlock;
    }
}