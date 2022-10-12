// This script is designed to test the solidity smart contract - SuppyChain.sol -- and the various functions within
// Declare a variable and assign the compiled smart contract artifact
var SupplyChain = artifacts.require("SupplyChain");

contract("SupplyChain", function (accounts) {
  // Declare few constants and assign a few sample accounts generated by ganache-cli
  var sku = 1;
  var upc = 1;
  const originProducerName = "John Doe";
  const originProducerInformation = "Yarray Valley";
  const productNotes = "Best wood for Guitar";
  const productPrice = web3.utils.toWei(String(1), "ether");
  var itemState = 0;
  // const consumerID = "0x00000000000000000000000000000000000000";
  const consumerID = "0x0000000000000000000000000000000000000000";

  console.log("ganache-cli accounts used here...");
  console.log("Contract Owner: accounts[0] ", accounts[0]);
  console.log("Origin producer: accounts[1] ", accounts[1]);
  console.log("Distributor: accounts[2] ", accounts[2]);
  console.log("Retailer: accounts[3] ", accounts[3]);
  console.log("Consumer: accounts[4] ", accounts[4]);

  it("Testing smart contract function collectMaterials() that allows a producer to create a guitar", async () => {
    const supplyChain = await SupplyChain.deployed();

    // Declare and Initialize a variable for event
    var eventEmitted = false;

    supplyChain.MaterialsSelected(null, (error, event) => {
      eventEmitted = true;
    });

    // Register a producer that will collect materials
    await supplyChain.registerProducer(accounts[1]);

    // Mark as Materials Selected
    await supplyChain.collectMaterials(
      originProducerName,
      originProducerInformation,
      productNotes,
      productPrice,
      { from: accounts[1] }
    );

    const result = await supplyChain.getItem.call(1);

    assert.equal(result[0], sku, "Error: Invalid item SKU");
    assert.equal(result[1], upc, "Error: Invalid item UPC");
    assert.equal(result[2], productPrice, "Error: Invalid item price");
    assert.equal(result[3], productNotes, "Error: Invalid item notes");
    assert.equal(
      result[4],
      originProducerInformation,
      "Error: Invalid producer information"
    );
    assert.equal(result[5], 0, "Error: Invalid product state");
  });

  it("Testing smart contract function shapeItem() that allows the producer owner to shape the materials collected", async () => {
    const supplyChain = await SupplyChain.deployed();

    var eventEmitted = false;

    supplyChain.Shaped(null, (error, event) => {
      eventEmitted = true;
    });

    const item = await supplyChain.getItem.call(1);

    await supplyChain.shapeItem(item[1], { from: accounts[1] });

    const itemShaped = await supplyChain.getItem.call(1);

    assert.equal(itemShaped[5], 1, "Error: Invalid product state");
  });

  it("Testing smart contract function buildItem() that allows the producer owner build the item", async () => {
    const supplyChain = await SupplyChain.deployed();

    var eventEmitted = false;

    supplyChain.Built(null, (error, event) => {
      eventEmitted = true;
    });

    const item = await supplyChain.getItem.call(1);

    await supplyChain.buildItem(item[1], { from: accounts[1] });

    const itemShaped = await supplyChain.getItem.call(1);

    assert.equal(itemShaped[5], 2, "Error: Invalid product state");
  });

  it("Testing smart contract function qualityControl() that allows the qualityController to check the quality of the item", async () => {
    const supplyChain = await SupplyChain.deployed();

    var eventEmitted = false;

    supplyChain.QualityControlled(null, (error, event) => {
      eventEmitted = true;
    });

    await supplyChain.registerQualityController(accounts[2]);

    const item = await supplyChain.getItem.call(1);

    await supplyChain.controlQuality(item[1], { from: accounts[2] });

    const itemShaped = await supplyChain.getItem.call(1);

    assert.equal(itemShaped[5], 3, "Error: Invalid product state");
  });

  it("Testing smart contract function putForSale() that puts the item for sale", async () => {
    const supplyChain = await SupplyChain.deployed();

    var eventEmitted = false;

    supplyChain.ForSale(null, (error, event) => {
      eventEmitted = true;
    });

    const item = await supplyChain.getItem.call(1);

    await supplyChain.putForSale(item[1], { from: accounts[1] });

    const itemShaped = await supplyChain.getItem.call(1);

    assert.equal(itemShaped[5], 4, "Error: Invalid product state");
  });

  //   // 1st Test
  //   it("Testing smart contract function harvestItem() that allows a farmer to harvest coffee", async () => {
  //     const supplyChain = await SupplyChain.deployed();

  //     // Declare and Initialize a variable for event
  //     var eventEmitted = false;

  //     // Watch the emitted event Harvested()
  //     var event = supplyChain.Harvested();
  //     await event.watch((err, res) => {
  //       eventEmitted = true;
  //     });

  //     // Mark an item as Harvested by calling function harvestItem()
  //     await supplyChain.harvestItem(
  //       upc,
  //       originFarmerID,
  //       originFarmName,
  //       originFarmInformation,
  //       originFarmLatitude,
  //       originFarmLongitude,
  //       productNotes
  //     );

  //     // Retrieve the just now saved item from blockchain by calling function fetchItem()
  //     const resultBufferOne = await supplyChain.fetchItemBufferOne.call(upc);
  //     const resultBufferTwo = await supplyChain.fetchItemBufferTwo.call(upc);

  //     // Verify the result set
  //     assert.equal(resultBufferOne[0], sku, "Error: Invalid item SKU");
  //     assert.equal(resultBufferOne[1], upc, "Error: Invalid item UPC");
  //     assert.equal(
  //       resultBufferOne[2],
  //       originFarmerID,
  //       "Error: Missing or Invalid ownerID"
  //     );
  //     assert.equal(
  //       resultBufferOne[3],
  //       originFarmerID,
  //       "Error: Missing or Invalid originFarmerID"
  //     );
  //     assert.equal(
  //       resultBufferOne[4],
  //       originFarmName,
  //       "Error: Missing or Invalid originFarmName"
  //     );
  //     assert.equal(
  //       resultBufferOne[5],
  //       originFarmInformation,
  //       "Error: Missing or Invalid originFarmInformation"
  //     );
  //     assert.equal(
  //       resultBufferOne[6],
  //       originFarmLatitude,
  //       "Error: Missing or Invalid originFarmLatitude"
  //     );
  //     assert.equal(
  //       resultBufferOne[7],
  //       originFarmLongitude,
  //       "Error: Missing or Invalid originFarmLongitude"
  //     );
  //     assert.equal(resultBufferTwo[5], 0, "Error: Invalid item State");
  //     assert.equal(eventEmitted, true, "Invalid event emitted");
  //   });

  //   // 2nd Test
  //   it("Testing smart contract function processItem() that allows a farmer to process coffee", async () => {
  //     const supplyChain = await SupplyChain.deployed();

  //     // Declare and Initialize a variable for event

  //     // Watch the emitted event Processed()

  //     // Mark an item as Processed by calling function processtItem()

  //     // Retrieve the just now saved item from blockchain by calling function fetchItem()

  //     // Verify the result set
  //   });

  //   // 3rd Test
  //   it("Testing smart contract function packItem() that allows a farmer to pack coffee", async () => {
  //     const supplyChain = await SupplyChain.deployed();

  //     // Declare and Initialize a variable for event

  //     // Watch the emitted event Packed()

  //     // Mark an item as Packed by calling function packItem()

  //     // Retrieve the just now saved item from blockchain by calling function fetchItem()

  //     // Verify the result set
  //   });

  //   // 4th Test
  //   it("Testing smart contract function sellItem() that allows a farmer to sell coffee", async () => {
  //     const supplyChain = await SupplyChain.deployed();

  //     // Declare and Initialize a variable for event

  //     // Watch the emitted event ForSale()

  //     // Mark an item as ForSale by calling function sellItem()

  //     // Retrieve the just now saved item from blockchain by calling function fetchItem()

  //     // Verify the result set
  //   });

  //   // 5th Test
  //   it("Testing smart contract function buyItem() that allows a distributor to buy coffee", async () => {
  //     const supplyChain = await SupplyChain.deployed();

  //     // Declare and Initialize a variable for event

  //     // Watch the emitted event Sold()
  //     var event = supplyChain.Sold();

  //     // Mark an item as Sold by calling function buyItem()

  //     // Retrieve the just now saved item from blockchain by calling function fetchItem()

  //     // Verify the result set
  //   });

  //   // 6th Test
  //   it("Testing smart contract function shipItem() that allows a distributor to ship coffee", async () => {
  //     const supplyChain = await SupplyChain.deployed();

  //     // Declare and Initialize a variable for event

  //     // Watch the emitted event Shipped()

  //     // Mark an item as Sold by calling function buyItem()

  //     // Retrieve the just now saved item from blockchain by calling function fetchItem()

  //     // Verify the result set
  //   });

  //   // 7th Test
  //   it("Testing smart contract function receiveItem() that allows a retailer to mark coffee received", async () => {
  //     const supplyChain = await SupplyChain.deployed();

  //     // Declare and Initialize a variable for event

  //     // Watch the emitted event Received()

  //     // Mark an item as Sold by calling function buyItem()

  //     // Retrieve the just now saved item from blockchain by calling function fetchItem()

  //     // Verify the result set
  //   });

  //   // 8th Test
  //   it("Testing smart contract function purchaseItem() that allows a consumer to purchase coffee", async () => {
  //     const supplyChain = await SupplyChain.deployed();

  //     // Declare and Initialize a variable for event

  //     // Watch the emitted event Purchased()

  //     // Mark an item as Sold by calling function buyItem()

  //     // Retrieve the just now saved item from blockchain by calling function fetchItem()

  //     // Verify the result set
  //   });

  //   // 9th Test
  //   it("Testing smart contract function fetchItemBufferOne() that allows anyone to fetch item details from blockchain", async () => {
  //     const supplyChain = await SupplyChain.deployed();

  //     // Retrieve the just now saved item from blockchain by calling function fetchItem()

  //     // Verify the result set:
  //   });

  //   // 10th Test
  //   it("Testing smart contract function fetchItemBufferTwo() that allows anyone to fetch item details from blockchain", async () => {
  //     const supplyChain = await SupplyChain.deployed();

  //     // Retrieve the just now saved item from blockchain by calling function fetchItem()

  //     // Verify the result set:
  //   });
});
