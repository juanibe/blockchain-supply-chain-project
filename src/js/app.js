App = {
  web3Provider: null,
  contracts: {},
  emptyAddress: "0x0000000000000000000000000000000000000000",
  sku: 0,
  upc: 0,
  metamaskAccountID: "0x0000000000000000000000000000000000000000",
  ownerID: "0x0000000000000000000000000000000000000000",
  originProducerID: "0x0000000000000000000000000000000000000000",
  originProducerName: null,
  originProducerInformation: null,
  productId: null,
  productNotes: null,
  productPrice: null,
  itemState: null,
  consumerID: "0x0000000000000000000000000000000000000000",

  init: async function () {
    App.readForm();
    /// Setup access to blockchain
    return await App.initWeb3();
  },

  readForm: function () {
    console.log($("#sku").val(), "HERE!");
    App.sku = $("#sku").val();
    App.upc = $("#upc").val();
    App.ownerID = $("#ownerID").val();
    App.originProducerID = $("#originFarmerID").val();
    App.originProducerName = $("#originFarmName").val();
    App.originProducerInformation = $("#originFarmInformation").val();
    App.productNotes = $("#productNotes").val();
    App.productPrice = $("#productPrice").val();
    App.consumerID = $("#consumerID").val();
  },

  initWeb3: async function () {
    /// Find or Inject Web3 Provider
    /// Modern dapp browsers...
    if (window.ethereum) {
      App.web3Provider = window.ethereum;
      try {
        // Request account access
        await window.ethereum.enable();
      } catch (error) {
        // User denied account access...
        console.error("User denied account access");
      }
    }
    // Legacy dapp browsers...
    else if (window.web3) {
      App.web3Provider = window.web3.currentProvider;
    }
    // If no injected web3 instance is detected, fall back to Ganache
    else {
      App.web3Provider = new Web3.providers.HttpProvider(
        "http://localhost:8545"
      );
    }

    App.getMetaskAccountID();

    return App.initSupplyChain();
  },

  getMetaskAccountID: function () {
    web3 = new Web3(App.web3Provider);

    // Retrieving accounts
    web3.eth.getAccounts(function (err, res) {
      if (err) {
        console.log("Error:", err);
        return;
      }
      console.log("getMetaskID:", res);
      App.metamaskAccountID = res[0];
    });
  },

  initSupplyChain: function () {
    /// Source the truffle compiled smart contracts
    var jsonSupplyChain = "../../build/contracts/SupplyChain.json";

    /// JSONfy the smart contracts
    $.getJSON(jsonSupplyChain, function (data) {
      var SupplyChainArtifact = data;
      App.contracts.SupplyChain = TruffleContract(SupplyChainArtifact);
      App.contracts.SupplyChain.setProvider(App.web3Provider);

      App.fetchItemBufferOne();
      App.fetchItemBufferTwo();
      App.fetchEvents();
    });

    return App.bindEvents();
  },

  bindEvents: function () {
    $(document).on("click", App.handleButtonClick);
  },

  handleButtonClick: async function (event) {
    event.preventDefault();

    App.getMetaskAccountID();

    var processId = parseInt($(event.target).data("id"));
    console.log("in other", processId);
    switch (processId) {
      case 1:
        return await App.collectMaterials(event);
        break;
      case 2:
        return await App.shapeItem(event);
        break;
      case 3:
        return await App.buildItem(event);
        break;
      case 4:
        return await App.controlQuality(event);
        break;
      case 5:
        return await App.putForSale(event);
        break;
      case 6:
        return await App.buyGuitar(event);
        break;
      case 7:
        return await App.receiveItem(event);
        break;
      case 8:
        return await App.purchaseItem(event);
        break;
      case 9:
        return await App.fetchItem(event);
        break;
      case 10:
        return await App.registerProducer(event);
        break;
      case 11:
        return await App.registerQualityController(event);
        break;
    }
  },

  collectMaterials: function (event) {
    event.preventDefault();

    const originProducerName = document.getElementById("producer-name").value;
    const originProducerInformation =
      document.getElementById("producer-info").value;
    const productNotes = document.getElementById("product-notes").value;
    const productPrice = document.getElementById("product-price").value;

    App.contracts.SupplyChain.deployed()
      .then(function (instance) {
        return instance.collectMaterials(
          originProducerName,
          originProducerInformation,
          productNotes,
          web3.toWei(String(productPrice), "ether"),
          { from: App.metamaskAccountID }
        );
      })
      .then(function (result) {
        $("#collected").text(
          "Materials collected.",
          result.receipt.transactionHash
        );
      })
      .catch(function (err) {
        console.log(err, "error complete");
        console.log(err.message);
      });
  },

  /** Retrieves an item */
  fetchItem: function (event) {
    const upc = document.getElementById("upc").value;

    App.contracts.SupplyChain.deployed()
      .then(async function (instance) {
        return await instance.getItem(upc);
      })
      .then(function (result) {
        const priceToEther = web3.fromWei(result[2], "ether");
        let productState;

        switch (Number(result[5])) {
          case 0:
            productState = "Materials Selected";
            break;
          case 1:
            productState = "Materials shaped";
            break;
          case 2:
            productState = "Guitar built";
            break;
          case 3:
            productState = "Quality Controlled";
            break;
          case 4:
            productState = "For sale";
            break;
        }

        $("#get-sku").text("SKU: " + result[0]);
        $("#get-upc").text("UPC: " + result[1]);
        $("#get-price").text("PRICE: " + priceToEther + " ETH");
        $("#get-notes").text("PRODUCT NOTES: " + result[3]);
        $("#get-producer-info").text("PRODUCER INFORMATION: " + result[4]);
        $("#get-state").text("PRODUCT STATE: " + productState);
      })
      .catch(function (err) {
        console.log(err);
      });
  },

  /** Shapes an item */
  shapeItem: function (event) {
    event.preventDefault();
    const upc = document.getElementById("upc-state").value;
    App.contracts.SupplyChain.deployed()
      .then(function (instance) {
        return instance.shapeItem(upc, { from: App.metamaskAccountID });
      })
      .then(function (result) {
        $("#state").text("State changed");
        console.log("processItem", result);
      })
      .catch(function (err) {
        console.log(err.message);
      });
  },

  /** Builds an item */
  buildItem: function (event) {
    event.preventDefault();
    const upc = document.getElementById("upc-state").value;
    App.contracts.SupplyChain.deployed()
      .then(function (instance) {
        return instance.buildItem(upc, { from: App.metamaskAccountID });
      })
      .then(function (result) {
        $("#state").text("State changed");
      })
      .catch(function (err) {
        console.log(err.message);
      });
  },

  /** Control the quality of the item */
  controlQuality: function (event) {
    event.preventDefault();
    const upc = document.getElementById("upc-state").value;
    App.contracts.SupplyChain.deployed()
      .then(function (instance) {
        return instance.controlQuality(upc, { from: App.metamaskAccountID });
      })
      .then(function (result) {
        $("#state").text("State changed");
      })
      .catch(function (err) {
        console.log(err.message);
      });
  },

  /** Put item on sale */
  putForSale: function (event) {
    event.preventDefault();
    const upc = document.getElementById("upc-state").value;
    App.contracts.SupplyChain.deployed()
      .then(function (instance) {
        return instance.putForSale(upc, { from: App.metamaskAccountID });
      })
      .then(function (result) {
        $("#state").text("State changed");
      })
      .catch(function (err) {
        console.log(err.message);
      });
  },

  /** Buy the item */
  buyGuitar: function (event) {
    event.preventDefault();
    const upc = document.getElementById("upc-state").value;
    App.contracts.SupplyChain.deployed()
      .then(function (instance) {
        return instance.getItem(upc).then(function (result) {
          console.log(result, "ITEM");
          return instance.buyGuitar(upc, {
            from: App.metamaskAccountID,
            value: result[2], //web3.toWei(result[2], "ether"),
          });
        });
      })
      .then(function (result) {
        $("#state").text("Item bought");
      })
      .catch(function (err) {
        console.log(err.message);
      });
  },

  /** Register a producer */
  registerProducer: function (event) {
    event.preventDefault();
    const producerAddress = document.getElementById("producer-address").value;
    App.contracts.SupplyChain.deployed()
      .then(function (instance) {
        return instance.registerProducer(producerAddress, {
          from: App.metamaskAccountID,
        });
      })
      .then(function (result) {
        console.log("RESULT", result);
        $("#register-producer-result").text("Producer registered successfully");
      })
      .catch(function (err) {
        console.log(err.message);
      });
  },

  registerQualityController: function (event) {
    event.preventDefault();
    const qualityControllerAddress =
      document.getElementById("quality-address").value;
    App.contracts.SupplyChain.deployed()
      .then(function (instance) {
        return instance.registerQualityController(qualityControllerAddress, {
          from: App.metamaskAccountID,
        });
      })
      .then(function (result) {
        $("#register-quality-result").text(
          "Quality controller registered successfully"
        );
      })
      .catch(function (err) {
        console.log(err.message);
      });
  },

  packItem: function (event) {
    event.preventDefault();
    var processId = parseInt($(event.target).data("id"));

    App.contracts.SupplyChain.deployed()
      .then(function (instance) {
        return instance.packItem(App.upc, { from: App.metamaskAccountID });
      })
      .then(function (result) {
        $("#ftc-item").text(result);
        console.log("packItem", result);
      })
      .catch(function (err) {
        console.log(err.message);
      });
  },

  sellItem: function (event) {
    event.preventDefault();
    var processId = parseInt($(event.target).data("id"));

    App.contracts.SupplyChain.deployed()
      .then(function (instance) {
        const productPrice = web3.toWei(1, "ether");
        console.log("productPrice", productPrice);
        return instance.sellItem(App.upc, App.productPrice, {
          from: App.metamaskAccountID,
        });
      })
      .then(function (result) {
        $("#ftc-item").text(result);
        console.log("sellItem", result);
      })
      .catch(function (err) {
        console.log(err.message);
      });
  },

  buyItem: function (event) {
    event.preventDefault();
    var processId = parseInt($(event.target).data("id"));

    App.contracts.SupplyChain.deployed()
      .then(function (instance) {
        const walletValue = web3.toWei(3, "ether");
        return instance.buyItem(App.upc, {
          from: App.metamaskAccountID,
          value: walletValue,
        });
      })
      .then(function (result) {
        $("#ftc-item").text(result);
        console.log("buyItem", result);
      })
      .catch(function (err) {
        console.log(err.message);
      });
  },

  shipItem: function (event) {
    event.preventDefault();
    var processId = parseInt($(event.target).data("id"));

    App.contracts.SupplyChain.deployed()
      .then(function (instance) {
        return instance.shipItem(App.upc, { from: App.metamaskAccountID });
      })
      .then(function (result) {
        $("#ftc-item").text(result);
        console.log("shipItem", result);
      })
      .catch(function (err) {
        console.log(err.message);
      });
  },

  receiveItem: function (event) {
    event.preventDefault();
    var processId = parseInt($(event.target).data("id"));

    App.contracts.SupplyChain.deployed()
      .then(function (instance) {
        return instance.receiveItem(App.upc, { from: App.metamaskAccountID });
      })
      .then(function (result) {
        $("#ftc-item").text(result);
        console.log("receiveItem", result);
      })
      .catch(function (err) {
        console.log(err.message);
      });
  },

  purchaseItem: function (event) {
    event.preventDefault();
    var processId = parseInt($(event.target).data("id"));

    App.contracts.SupplyChain.deployed()
      .then(function (instance) {
        return instance.purchaseItem(App.upc, { from: App.metamaskAccountID });
      })
      .then(function (result) {
        $("#ftc-item").text(result);
        console.log("purchaseItem", result);
      })
      .catch(function (err) {
        console.log(err.message);
      });
  },

  fetchItemBufferOne: function () {
    ///   event.preventDefault();
    ///    var processId = parseInt($(event.target).data('id'));
    App.upc = $("#upc").val();
    console.log("upc", App.upc);

    App.contracts.SupplyChain.deployed()
      .then(function (instance) {
        return instance.fetchItemBufferOne(App.upc);
      })
      .then(function (result) {
        $("#ftc-item").text(result);
        console.log("fetchItemBufferOne", result);
      })
      .catch(function (err) {
        console.log(err.message);
      });
  },

  fetchItemBufferTwo: function () {
    ///    event.preventDefault();
    ///    var processId = parseInt($(event.target).data('id'));

    App.contracts.SupplyChain.deployed()
      .then(function (instance) {
        return instance.fetchItemBufferTwo.call(App.upc);
      })
      .then(function (result) {
        $("#ftc-item").text(result);
        console.log("fetchItemBufferTwo", result);
      })
      .catch(function (err) {
        console.log(err.message);
      });
  },

  fetchEvents: function () {
    if (
      typeof App.contracts.SupplyChain.currentProvider.sendAsync !== "function"
    ) {
      App.contracts.SupplyChain.currentProvider.sendAsync = function () {
        return App.contracts.SupplyChain.currentProvider.send.apply(
          App.contracts.SupplyChain.currentProvider,
          arguments
        );
      };
    }

    App.contracts.SupplyChain.deployed()
      .then(function (instance) {
        var events = instance.allEvents(function (err, log) {
          if (!err)
            $("#ftc-events").append(
              "<li>" + log.event + " - " + log.transactionHash + "</li>"
            );
        });
      })
      .catch(function (err) {
        console.log(err.message);
      });
  },
};

$(function () {
  $(window).load(function () {
    App.init();
  });
});
