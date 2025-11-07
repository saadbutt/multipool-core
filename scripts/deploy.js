const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying EvmSort contract...\n");

  // Get deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);
  console.log("Balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH\n");

  // Deploy required libraries (MaxHeap and MinHeap)
  console.log("Deploying required libraries...");
  const MaxHeap = await ethers.getContractFactory("MaxHeap");
  const maxHeap = await MaxHeap.deploy();
  await maxHeap.waitForDeployment();

  const MinHeap = await ethers.getContractFactory("MinHeap");
  const minHeap = await MinHeap.deploy();
  await minHeap.waitForDeployment();
  console.log("  Libraries deployed\n");

  // Deploy EvmSort contract
  console.log("Deploying EvmSort...");
  const EvmSort = await ethers.getContractFactory("EvmSort", {
    libraries: {
      MaxHeap: await maxHeap.getAddress(),
      MinHeap: await minHeap.getAddress(),
    },
  });
  const evmSort = await EvmSort.deploy();
  await evmSort.waitForDeployment();
  const evmSortAddress = await evmSort.getAddress();

  console.log("  EvmSort deployed to:", evmSortAddress);

  // Save deployment info
  const fs = require("fs");
  const deploymentInfo = {
    network: (await ethers.provider.getNetwork()).name,
    chainId: (await ethers.provider.getNetwork()).chainId.toString(),
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    evmSortAddress: evmSortAddress,
    libraries: {
      MaxHeap: await maxHeap.getAddress(),
      MinHeap: await minHeap.getAddress(),
    },
  };

  const deploymentsDir = "./deployments";
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir);
  }

  const filename = `${deploymentsDir}/deployment-${Date.now()}.json`;
  fs.writeFileSync(filename, JSON.stringify(deploymentInfo, null, 2));
  console.log("\n Deployment info saved to:", filename);

  console.log("\nDeployment complete! 🎉");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
