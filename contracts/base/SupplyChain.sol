// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract SupplyChain{

    address owner;

    // Define a variable called 'upc' for Universal Product Code (UPC)
    uint upc;

    // Define a variable called 'sku' for Stock Keeping Unit (SKU)
    uint sku;

    // Define a public mapping 'items' that maps the UPC to an Item.
    mapping (uint => Item) items;

    enum State { 
        MaterialSelection, 
        Shaped,  
        Built,     
        QualityControlled,
        ForSale,
        Sold,
        Shipped,
        Received,
        Purchased
    }

    struct Item {
        uint    sku;  // Stock Keeping Unit (SKU)
        uint    upc; // Universal Product Code (UPC), generated by the Farmer, goes on the package, can be verified by the Consumer
        address ownerID;  // Metamask-Ethereum address of the current owner as the product moves through 8 stages
        address originProducerID; // Metamask-Ethereum address of the Farmer
        string  originProducerName; // Farmer Name
        string  originProducerInformation;  // Farmer Information
        uint    productID;  // Product ID potentially a combination of upc + sku
        string  productNotes; // Product Notes
        uint    productPrice; // Product Price
        State   itemState;  // Product State as represented in the enum above
        address retailerID; // Metamask-Ethereum address of the Retailer
        address payable consumerID; // Metamask-Ethereum address of the Consumer
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

      // Define a modifer that verifies the Caller
    modifier verifyCaller (address _address) {
        require(msg.sender == _address); 
        _;
    }

    // Define a modifier that checks if the paid amount is sufficient to cover the price
    modifier paidEnough(uint _price) { 
        require(msg.value >= _price); 
        _;
    }

    // Define a modifier that checks the price and refunds the remaining balance
    modifier checkValue(uint _upc) {
        _;
        uint _price = items[_upc].productPrice;
        uint amountToReturn = msg.value - _price;
        items[_upc].consumerID.transfer(amountToReturn);
    }

    // Define modifiers to check the states

    modifier areMaterialsSelected(uint _upc) {
        require(items[_upc].itemState == State.MaterialSelection);
        _;
    }

    modifier hasBeenShaped(uint _upc) {
        require(items[_upc].itemState == State.Shaped);
        _;
    }

    modifier hasBeenBuilt(uint _upc) {
        require(items[_upc].itemState == State.Built);
        _;
    }

    modifier hasBeenControlled(uint _upc) {
        require(items[_upc].itemState == State.QualityControlled);
        _;
    }

    modifier isForSale(uint _upc){
        require(items[_upc].itemState == State.ForSale);
        _;
    }

    modifier isSold(uint _upc){
        require(items[_upc].itemState == State.Sold);
        _;
    }

    modifier isShipped(uint _upc){
        require(items[_upc].itemState == State.Shipped);
        _;
    }

    modifier received(uint _upc){
        require(items[_upc].itemState == State.Received);
        _;
    }

    modifier purchased(uint _upc){
        require(items[_upc].itemState == State.Purchased);
        _;
    }

}