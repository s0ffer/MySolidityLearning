// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    // function to set payment data into nested mapping (address > item ID > pushing data to Array) ! ONLY OWNER !
    function setPayment(address _user, uint _amount, uint _item) public onlyOwner {
        Payment memory newPayment = Payment({
            amount: _amount,
            timestamp: block.timestamp,
            user: _user
        });
        
        nestedPayment[_user][_item].push(newPayment); 
    }
    // function shows data from nested mapping (address > item ID > index in Array > Payment structure)
    function getPayment(address _user, uint _item, uint _paymentIndex) public view returns(Payment memory info) {
        require(_paymentIndex <  nestedPayment[_user][_item].length, "Index out of range");
        return nestedPayment[_user][_item][_paymentIndex];
    }
    // function executes payment, requires 10,000 wei (Item price), pushing payment data into nested mapping (addr > item ID)
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

    // function reseting payment to zero in nested mapping, ! ONLY OWNER ! 
    function resetPayment(address _user, uint _paymentIndex, uint _item) public onlyOwner {
        require(_paymentIndex <  nestedPayment[_user][_item].length, "Index out of range");
        delete nestedPayment[_user][_item][_paymentIndex];
    }

    // function creating Item structure, includes structure in structure ! ONLY OWNER! 
    function setItem(uint _itemId, string memory _name, string memory _rare, uint _damage, uint _health) public onlyOwner {
        Item storage newItem = items[_itemId];

        newItem.name = _name;
        newItem.rarity = _rare;
        newItem.attribute = Stat({ // changing values in structure of structure
            damage: _damage,
            durability: _health
        });
    }

    // function shows info about item from items mapping
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

    // function that execute another function from this contract for variable to calculate profit 
    function sumProfit(uint _itemId) public view returns(uint) {
        return getItemAmount(_itemId) * 10000; // variable from another function multiply by 10,000 (WEI)
    }

    // function that gets how many times item crafted, executing for sumProfit function
    function getItemAmount(uint _itemId) internal view returns(uint count) {
        return items[_itemId].crafted; 
    }
}