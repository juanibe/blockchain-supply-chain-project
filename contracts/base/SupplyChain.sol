// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../contracts/access-control/ProducerRol.sol";
import "../../contracts/access-control/QualityController.sol";


contract SupplyChain is ProducerRole, QualityControllerRole {

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
        address originProducerID; // Metamask-Ethereum address of the Producer (The producer is the owner)
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
                originProducerID: msg.sender, 
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
}

/**

Available Accounts
==================
(0) 0xe7b90611b4759b3547B9E5Acb3B87156Ea22A0f7 (100 ETH)
(1) 0x06fd23810F0a1C92Ca147122C0706e5b9A604305 (100 ETH)
(2) 0x2FAF42eBC4d8FDf7882F2490378770Aae5cCcF29 (100 ETH)
(3) 0xB51Ca7f2C5E55495C112f6673A079A905A04d42C (100 ETH)
(4) 0x669ae4E93425Eee715320F0064a6621226a9d7bf (100 ETH)
(5) 0xF5F2F3EC2117E73ff263323385fFF4beCf492616 (100 ETH)
(6) 0x9b145a1cDd83e6F64fEc6E5647F7b6d8D4422396 (100 ETH)
(7) 0x6EA37B979d6bE2530bE172CB00b50A220bABEBcB (100 ETH)
(8) 0xB380bee2659B967B2f31FcB6Bd868d6E8edC4748 (100 ETH)
(9) 0xda79d1BA691F2910Cc38AE04FBAcD9d9c65B53bc (100 ETH)

Private Keys
==================
(0) 0xd0ff5b47f5057f30c629821c5dd7558f2074f2ae708101de645cbecbabe24746 => Owner of contract
(1) 0x5197499a4ef3fb033cd74cd9f0eb5bef4c6b687a7e48a8e3656fc0323d1b2b00 => Producer (Owner of product)
(2) 0x8cc976b02ef61a8b9d21e998c7ff42e1672e6409f3623e5022fc2b94be3d3d81 => Producer
(3) 0x4629c60e6ddfabd283eed9856ad5ccffd02e9ac4d203c95b53d98902cfdbc9c4
(4) 0x95980968d2bcd9a58758549b6f8ea5a312660f51d74043a56bb217b57bf123b1
(5) 0xa797a91e413ce73177073fa2ec621b518312f5a37a3f8262628853dce4b6e852
(6) 0x0f23b765895b1a2eafa39e0fbb0fd1f493244a6c338059004dc5be86a29c0f9d
(7) 0x6ac076a4866a98046c711a677125e425f257e5f8c4e55548d27e2a17acfa71ff
(8) 0xe71cda93eabe668c1f151a2f2508817d87c1a5d62f049e0ccc14fa633671f996
(9) 0xd9b38328fabad4a5c3190d01f9a992d05755276f208ae0bfbd4f20f3a0d3444e

 */