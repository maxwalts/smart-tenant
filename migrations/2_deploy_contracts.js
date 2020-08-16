const Lease = artifacts.require("./Lease.sol");
const TenantAddress = "0x9585d2dCc5328be860210018a2f0F17b7fd8a56E"; //replace with desired tenant address
const DefaultTime = 1000; //replace with desired default expiration

module.exports = function (deployer) {
  deployer.deploy(Lease, TenantAddress, DefaultTime);
};
