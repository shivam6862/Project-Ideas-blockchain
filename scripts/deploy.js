const hre = require("hardhat");

async function main() {
  // for EventTicketsPlatform
  const EventTicketsPlatform = await hre.ethers.deployContract(
    "EventTicketsPlatform"
  );
  const response = await EventTicketsPlatform.waitForDeployment();
  console.log(` deployed to ${EventTicketsPlatform}`);
  console.log("EventTicketsPlatform deployed to:", response);

  // for RideSharing
  const RideSharing = await hre.ethers.getContractFactory("RideSharing");
  const rideSharing = await RideSharing.deploy();
  await rideSharing.deployed();
  console.log("RideSharing deployed to:", rideSharing.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// npx hardhat compile
// npx hardhat node
// npx hardhat run scripts/deploy.js --network localhost
// npx hardhat test
