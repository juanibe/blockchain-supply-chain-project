// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../contracts/access-control/ProducerRol.sol";
import "../../contracts/access-control/QualityController.sol";
import "../../contracts/access-control/ConsumerRol.sol";


contract SupplyChain is ProducerRole, QualityControllerRole, ConsumerRole {

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
        uint    upc;
        //address ownerID;  // Metamask-Ethereum address of the current owner 
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

    // In the constructor set 'owner' to the address that instantiated the contract
    // and set 'sku' and 'upc' to 1
    constructor(){
        owner = msg.sender;
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
        State itemState
    ) 
    {
       Item memory item = items[_upc];
       return (
        item.sku,
        item.upc,
        item.productPrice,
        item.productNotes,
        item.originProducerInformation,
        item.itemState
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
                //ownerID: msg.sender, 
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
        addConsumer(msg.sender);
        emit Sold(_upc);
    }
}

/**

Available Accounts
==================
(0) 0xa699729c4F4fd4Fc2b91808cd90eCa49BC1C2629 (100 ETH)
(1) 0xc63e01B498fe54B5f5E00f220b918C541b233A0C (100 ETH) => PRODUCER 1
(2) 0x189FaFC8C5A1BD308C04511c95aaac290ec0Fb05 (100 ETH) => QUALITY
(3) 0x34990cBB3d155Ede16797e8736ff2a1cE6EceB33 (100 ETH) => CONSUMER
(4) 0x99Fdd2efDB7B7a631C7e48BcB9714181b0d6aDb8 (100 ETH)
(5) 0x995fBAa340448155762E1c6261282506b6344e49 (100 ETH)
(6) 0xacdf1010673A8368cb867CD5DDcF921Ce09Bc4A2 (100 ETH)
(7) 0x1e6DA1A8Ad426ea5cb037a6CBEc786Bbe0eEaEf0 (100 ETH)
(8) 0x1febec0687134Dd302E73C1453CB0942D47bf91E (100 ETH)
(9) 0xfA58d6215A9881F89AfF73C6efC493F5dB9f2F52 (100 ETH)

Private Keys
==================
(0) 0xcd6c3e49c9eb45ff7b51121a2b0236dd5e3dacd837d1dbe0c2147c91a7d69cdd
(1) 0xefdbda6c9e1684509d913ac429272b70a9323482790a4a7bf66c29b0513c54a7 => PRODUCER 1
(2) 0xaf7a8d5f7533889c1a9ba59e75fa38a3e67d9edf66ef565b3419fee9931d2379 => QUALITY
(3) 0x98574dc21f659c642d118670a0dbe367d559492e154a136672324ad4dbc87235 => CONSUMER
(4) 0xdd45f850581753b2ea3461c6b8d627910789a57a3d90075d2416d5451e33db4b
(5) 0x9f109a60253079a83718e17ec8f5a4270490436bd5b50d3d0c632b0fd8439d7e
(6) 0x663c4b5c593dd5cfd453e40e33f5f6898bc6d208af3fe2903ec8fcd9e3f82c13
(7) 0xafd20eeb214905402503f9457bf77ae262077662f6b6522c025753170a8e430e
(8) 0x26b99202a3efcaee3494de60dca57f7f92c1e518d26248f97b4094214ee9383c
(9) 0xb6792cbc22494ba202b91226351988d470e0827209430ec1cf36ef1b5a46e539


 */