// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/// @title My contract from practicum two
/// @author s0ffer
/// @notice Here is my imaginary RPG shop mechanics contract
/// @dev Only for education, practice writing fucntions, data types
import "@openzeppelin/contracts/access/Ownable.sol";

contract PracticumTwo is Ownable(msg.sender) {
    // Creating structures
    struct Payment {
        uint amount;
        uint timestamp;
        address user;
    }
    // structure with structure in it & mapping
    struct Item {
        string name;
        string rarity;
        Stat attribute;
        mapping (address => bool) itemHolder;
        uint crafted;
    }
    // structure of structure
    struct Stat {
        uint damage;
        uint durability;
    }
    // structure for return value of function
    struct ItemReturn {
        string name;
        string rarity;
        uint damage;
        uint durability;
        bool owned;
        uint crafted;
    }
    // nested mapping includes mapping that includes Array of Payment structures (address > uint ID of item > uint index of value in array)
    mapping (address => mapping(uint => Payment[])) nestedPayment;
    mapping (uint => Item) items; // mapping includes structure
    // creating array of Payment structures
    Payment[] public paymentsArray;

    /// @notice Set payment data into nested mapping (address > item ID > pushing data to Array)
    /// @dev Worked in Remix IDE, !ONLY OWNER function!
    /// @param _user The address to set payment for
    /// @param _amount The amount of payment
    /// @param _item The ID of the item that was purchased
    function setPayment(address _user, uint _amount, uint _item) public onlyOwner {
        Payment memory newPayment = Payment({
            amount: _amount,
            timestamp: block.timestamp,
            user: _user
        });
        
        nestedPayment[_user][_item].push(newPayment); 
    }

    
    /// @notice Shows data from nested mapping (address > item ID > index in Array > Payment structure)
    /// @dev Worked in Remix IDE
    /// @param _user The address of user
    /// @param _item The ID of the item
    /// @param _paymentIndex The index of the payment
    /// @return info gets Payment type struct with information about payment
    function getPayment(address _user, uint _item, uint _paymentIndex) public view returns(Payment memory info) {
        require(_paymentIndex <  nestedPayment[_user][_item].length, "Index out of range");
        return nestedPayment[_user][_item][_paymentIndex];
    }
    
    
    /// @notice Executes payment, requires 10,000 wei (Item price), pushing payment data into nested mapping (addr > item ID)
    /// @dev Worked in Remix IDE
    /// @param _item The ID of the item that you want to buy
    function buyItem(uint _item) public payable {
        require(msg.value == 10000 wei, "Price is 10,000 wei!");
        Payment memory newPayment = Payment({
            amount: msg.value,
            timestamp: block.timestamp,
            user: msg.sender
        });
        
        nestedPayment[msg.sender][_item].push(newPayment);
        Item storage newItem = items[_item]; // creating variable for Item structure
        newItem.itemHolder[msg.sender] = true; // changing bool in Item structure (showing that msg.sender now own this item in structure) 
        newItem.crafted++;  // +1 count for crafted variable in Item structure
    }

    /// @notice Reseting payment to zero in nested mapping
    /// @dev Worked in Remix IDE, !ONLY OWNER function!
    /// @param _user The address of the user
    /// @param _item The ID of the item
    /// @param _paymentIndex The index of the payment
    function resetPayment(address _user, uint _paymentIndex, uint _item) public onlyOwner {
        require(_paymentIndex <  nestedPayment[_user][_item].length, "Index out of range");
        delete nestedPayment[_user][_item][_paymentIndex];
    }

    /// @notice Creating [Item] structure, includes structure in structure
    /// @dev Worked in Remix IDE,  !ONLY OWNER function!
    /// @param _itemId The index of the new item
    /// @param _name The name of the new item
    /// @param _rare The rare of the new item
    /// @param _damage The damage of the new item
    /// @param _health The health of the new item
    function setItem(uint _itemId, string memory _name, string memory _rare, uint _damage, uint _health) public onlyOwner {
        Item storage newItem = items[_itemId];

        newItem.name = _name;
        newItem.rarity = _rare;
        newItem.attribute = Stat({ // changing values in structure of structure
            damage: _damage,
            durability: _health
        });
    }

    /// @notice Shows info about item from items mapping
    /// @dev Worked in Remix IDE
    /// @param _itemId The index of the item
    /// @param _holderAddr The address of the item holder
    /// @return ItemReturn type struct information 
    function getItem(uint _itemId, address _holderAddr) public view returns(ItemReturn memory) {
        return ItemReturn({ // created form structure for return value
            name: items[_itemId].name,
            rarity: items[_itemId].rarity,
            damage: items[_itemId].attribute.damage, // takes value from structure in structure
            durability: items[_itemId].attribute.durability, // takes value from structure in structure
            owned: items[_itemId].itemHolder[_holderAddr], // takes value from mapping in structure
            crafted: items[_itemId].crafted
        });
    }

    /// @notice Executes another function from this contract for variable to calculate profit
    /// @dev Worked in Remix IDE
    /// @param _itemId The index of the item
    /// @return uint result of profit made by selling items  
    function sumProfit(uint _itemId) public view returns(uint) {
        return getItemAmount(_itemId) * 10000; // variable from another function multiply by 10,000 (WEI)
    }

    /// @notice Gets how many times item crafted, executing for sumProfit function
    /// @dev Worked in Remix IDE
    /// @param _itemId The index of the item
    /// @return count of how many times item was crafted
    function getItemAmount(uint _itemId) internal view returns(uint count) {
        return items[_itemId].crafted; 
    }
}