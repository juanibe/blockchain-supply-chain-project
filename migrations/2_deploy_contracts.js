// migrating the appropriate contracts
const ProducerRole = artifacts.require("./ProducerRole.sol");
const ConsumerRole = artifacts.require("./ConsumerRole.sol");

module.exports = function (deployer) {
  deployer.deploy(ProducerRole);
  deployer.deploy(ConsumerRole);
};
