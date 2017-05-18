var Rcoin = artifacts.require("./Rcoin.sol");

module.exports = function(deployer) {
  deployer.deploy(Rcoin);
};
