// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../contracts/core/Ownable.sol";
import "../../contracts/access-control/ProducerRol.sol";
import "../../contracts/access-control/QualityController.sol";


contract SupplyChain is Ownable, ProducerRole, QualityControllerRole {

    // address owner;

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
        uint    upc;
        address payable originProducerID; // Metamask-Ethereum address of the Producer (The producer is the owner)
        string  originProducerName; // Producer Name
        string  originProducerInformation;  // Producer Information
        address qualityControllerID; // Metamask-Ethereum address of the quality controller 
        uint    productId;  // Product ID potentially a combination of upc + sku
        string  productNotes; // Product Notes
        uint    productPrice; // Product Price
        State   itemState;  // Product State as represented in the enum above
        address payable consumerID; // Metamask-Ethereum address of the Consumer
    }

        // Define events
        event MaterialsSelected(uint upc);
        event Shaped(uint upc);
        event Built(uint upc);
        event QualityControlled(uint upc);
        event ForSale(uint upc);
        event Sold(uint upc);
        event Shipped(uint upc);
        event Received(uint upc);
        event Purchased(uint upc);


    // modifier onlyOwner() {
    //     require(msg.sender == owner);
    //     _;
    // }

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

    // In the constructor set 'owner' to the address that instantiated the contract
    // and set 'sku' and 'upc' to 1
    constructor(){
        // owner = msg.sender;
        sku = 1;
        upc = 1;
    }

    function registerProducer(address producerAddress) onlyOwner public returns(bool){
        addProducer(producerAddress);
        return true;
    }

    function registerQualityController(address qualityControllerAddress) onlyOwner public returns(bool){
        addQualityController(qualityControllerAddress);
        return true;
    }
    

    function getItem(uint _upc) public view returns (
        uint sku,
        uint upc,
        uint price,
        string memory productNotes,
        string memory originProducerInformation,
        State itemState,
        address consumerID
    ) 
    {
       Item memory item = items[_upc];
       return (
        item.sku,
        item.upc,
        item.productPrice,
        item.productNotes,
        item.originProducerInformation,
        item.itemState,
        item.consumerID
       );
    }

    

    /* 
      Define a function 'collectMaterials' that allows a producer to set the state as material collected. 
      Only a registered producer will be able to collect materials.
    */
    function collectMaterials(
        string memory _originProducerName, 
        string memory _originProducerInformation, 
        string memory _productNotes,
        uint _price
        ) onlyProducer payable public 
    {
        
        items[sku] = Item(
            {
                sku: sku, 
                upc: upc,
                originProducerID: payable(msg.sender), 
                originProducerName: _originProducerName, 
                originProducerInformation: _originProducerInformation, 
                productId: sku + upc, 
                productNotes: _productNotes, 
                productPrice: _price, 
                itemState: State.MaterialSelection, 
                consumerID: payable(address(0)),
                qualityControllerID: address(0)
            });

        emit MaterialsSelected(sku);

        sku = sku + 1;

        upc = upc + 1;
    }

    /**
       Shaping the items means to work the wood and different guitar parts in order to be 
       able to build the guitar.
       Only the producer can shape the item
    */
    function shapeItem(uint _upc) onlyProducer public areMaterialsSelected(_upc) {
        /* We check that the producer is the owner of the product */
        require(msg.sender == items[_upc].originProducerID);
        items[_upc].itemState = State.Shaped;
        emit Shaped(_upc);
    }

    /**
       Only the producer can build the item
    */
    function buildItem(uint _upc) onlyProducer public hasBeenShaped(_upc) {
        require(msg.sender == items[_upc].originProducerID);
        items[_upc].itemState = State.Built;
        emit Built(_upc);
    }

    /**
       Only an address with quality control rol can check the item quality.
    */
    function controlQuality(uint _upc) onlyQualityController public hasBeenBuilt(_upc) {
        items[_upc].itemState = State.QualityControlled;
        emit QualityControlled(_upc);
    }

    /**
       Only an address with quality control rol can check the item quality.
    */
    function putForSale(uint _upc) onlyProducer public hasBeenControlled(_upc) {
        items[_upc].itemState = State.ForSale;
        emit ForSale(_upc);
    }

    /**
       Buys guitar by comsumer
    */
    function buyGuitar(uint _upc) public isForSale(_upc) paidEnough(items[_upc].productPrice) checkValue(_upc) payable {
        items[_upc].itemState = State.Sold;
        items[_upc].originProducerID.transfer(items[_upc].productPrice);
        items[_upc].consumerID = payable(msg.sender);
        emit Sold(_upc);
    }

    /**
        Ships the item to the buyer
     */
     function shipItem(uint _upc) onlyProducer public isSold(_upc) {
        items[_upc].itemState = State.Shipped;
        emit Shipped(_upc);
     }

    /**
        Receive the item
        Only can be received by the consumer
     */
     function receiveItem(uint _upc) public isShipped(_upc) {
        require(msg.sender == items[_upc].consumerID, 'Only the buyer can receive the item');
        items[_upc].itemState = State.Received;
        emit Received(_upc);
     }
}