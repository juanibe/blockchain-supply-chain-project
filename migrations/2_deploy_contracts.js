// migrating the appropriate contracts
const ProducerRole = artifacts.require("./ProducerRole.sol");
const ConsumerRole = artifacts.require("./ConsumerRole.sol");
const SupplyChain = artifacts.require("./SupplyChain");

module.exports = function (deployer) {
  deployer.deploy(ProducerRole);
  deployer.deploy(ConsumerRole);
  deployer.deploy(SupplyChain);
};
