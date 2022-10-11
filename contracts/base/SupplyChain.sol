// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../contracts/access-control/ProducerRol.sol";

contract SupplyChain is ProducerRole {

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

    

    // Define a function 'collectMaterials' that allows a producer to set the state as material collected
    function collectMaterials(
        string memory _originProducerName, 
        string memory _originProducerInformation, 
        string memory _productNotes,
        uint _price
        ) onlyOwner payable public 
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
       Only the producer can shape the item
    */
    function shapeItem(uint _upc) public areMaterialsSelected(_upc) {
        items[_upc].itemState = State.Shaped;
        emit Shaped(_upc);
    }

    function buildItem(uint _upc) public hasBeenShaped(_upc) {
        items[_upc].itemState = State.Built;
        emit Built(_upc);
    }
}

/**

Available Accounts
==================
(0) 0xbDbc2E9338F1F6dB4208086a6B03605D892918F2 (100 ETH)
(1) 0x9D32ab539fFe375E9b4464bb752Ba4De1C679312 (100 ETH)
(2) 0xB209DbFd25048000152EcB08372d4dd74b555fFF (100 ETH)
(3) 0x12a4d32a225D162b67Fa0aC57D74C6990A8BdB0b (100 ETH)
(4) 0x37B6FC3399D20188713216eaa7658417AC6894A0 (100 ETH)
(5) 0x542D2a9d571FcdcaF6C67F7F5BE805bE3712edFf (100 ETH)
(6) 0x3004c6F4E0fff78f91dD6AF2Dc377e6581513cb4 (100 ETH)
(7) 0x55c1CA09f70EA04d880766f9272A8800Ebc7c8c7 (100 ETH)
(8) 0xE3Cd428160C7DFE298B934EceA87136f243c4F6d (100 ETH)
(9) 0xd8Ee6266312E4e8600480dd282544aa51a11d300 (100 ETH)

Private Keys
==================
(0) 0x4ab8067fd40ab45218a1f89410a5bb28f2ea5f870f6296c2b0d5a553e5aad8c4
(1) 0x76ada0724a1ee59014fec8001d4e82455b4f1a089bb56c917380d40c54e91cbc
(2) 0x23de27b6ef90cc2e9eb302a2358765144a07ce40f5d96d84c7dd3d8c66b95f86
(3) 0x32f1b7dea14e99f010d5c6b1497b257407801c52404251273e37c76304f5a7b2
(4) 0x67575b1f700a2b402edbfd62d8c62acd438793df0947d4b003a3e422f0385cd7
(5) 0x858a55e3edd8221b8a3774883645dad1af52b9b8263d2be0569d43cac82da281
(6) 0x3a68b8c5095349651546f8920eedeafad68130898a58fde56ad739186b285a72
(7) 0x0490140f8f10fec45c3973d1657f71296150a9f7c940ab32bf9292691e0eb8fa
(8) 0xd034c2025fdfe8380afa420773f3c25cc5db94e68ca4fd3529d1a5e3d0d16105
(9) 0x1ffa941e99e1f9a28a6513b787d7eccd610ad47c611fb781669ad0a45ef53791
 */