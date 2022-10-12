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

/**

Available Accounts
==================
(0) 0x895C9F39712Ed04cC9Ed714c34937a4940402d3f (100 ETH)
(1) 0x188E7c1a1164eb218Eb559C4335edb28758FB73e (100 ETH)
(2) 0x6DaF442C55B89b58Da204FE13dB5A9F354ef692D (100 ETH)
(3) 0x4A3F2f78912D35f1eC51074548aE4DAcC81c7B48 (100 ETH)
(4) 0x0917f5A4d84a2d80faf8ccc43F31870e407cC17D (100 ETH)
(5) 0xADBA588a5ea3F0A4e6d0577c87155F43919c3f22 (100 ETH)
(6) 0xf6DA23575304A1a12ef86BfADE6A42297F5f9115 (100 ETH)
(7) 0x9D2C1258e7E6Df36528726de26F1FfabABF28bd1 (100 ETH)
(8) 0x1BE2674B44f93816D777098EE94D413fBF686dee (100 ETH)
(9) 0xbce43f2F995F7Cc4C17c05E6Ec092aed90E14cEf (100 ETH)

Private Keys
==================
(0) 0x4688141b37d8467a38e87b02f8ddac4656b0ad4d958f81576ff306438be28698
(1) 0x0200339056d1ad92d41dbce84d096ab90bd682b7390d2b8e0575fd7a74a34c09
(2) 0xe1d549825c8d85690925788c256e909632c90e4c1eba2b2347c9cef78cb46240
(3) 0x638ffd1fbacd525bef6d4f979e5683d049aba3df80aee3fc67433b0a94312446
(4) 0x020f78dd7120d19cae2261b189911512d3b5854dbde170078fd73480eb3d9c0a
(5) 0xa2589f03f9ac864430f406aa12fbcc596b8b5af2eafbfea4d7341ef09fd80d83
(6) 0x9cb23331270a043981dd2f902b2b2d8587695e282932ebd339365c0921722b04
(7) 0xa2f957b99a58b8eeef316e845362e5827578aa685950d53f0ce7521de03ffaaf
(8) 0xf38169673e6adf04b095f02c03d4a5f451999dfc990b43450d25ee4f829744f6
(9) 0xb135a0b373b23abf641c63bb44bffaee376afc3a5fdf46d1587ce305fd49110b

 */