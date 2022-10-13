// migrating the appropriate contracts
const ProducerRole = artifacts.require("./ProducerRole.sol");
const SupplyChain = artifacts.require("./SupplyChain");

module.exports = function (deployer) {
  deployer.deploy(ProducerRole);
  deployer.deploy(SupplyChain);
};
