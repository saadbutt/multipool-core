const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("EvmSort - Max Sorting Tests", function () {
  let evmSort;
  let owner;

  beforeEach(async function () {
    [owner] = await ethers.getSigners();

    // Deploy libraries
    const MaxHeap = await ethers.getContractFactory("MaxHeap");
    const maxHeap = await MaxHeap.deploy();
    await maxHeap.waitForDeployment();

    const MinHeap = await ethers.getContractFactory("MinHeap");
    const minHeap = await MinHeap.deploy();
    await minHeap.waitForDeployment();

    // Deploy contract with linked libraries
    const EvmSort = await ethers.getContractFactory("EvmSort", {
      libraries: {
        MaxHeap: await maxHeap.getAddress(),
        MinHeap: await minHeap.getAddress(),
      },
    });
    evmSort = await EvmSort.deploy();
    await evmSort.waitForDeployment();
  });

  describe("setValue - Max Set", function () {
    it("Should add a single element to max set", async function () {
      await evmSort.setValue(100, true, true);
      expect(await evmSort.hasElement(100, true)).to.equal(true);
    });

    it("Should add multiple elements to max set", async function () {
      await evmSort.setValue(100, true, true);
      await evmSort.setValue(200, true, true);
      await evmSort.setValue(300, true, true);

      expect(await evmSort.hasElement(100, true)).to.equal(true);
      expect(await evmSort.hasElement(200, true)).to.equal(true);
      expect(await evmSort.hasElement(300, true)).to.equal(true);
    });

    it("Should remove an element from max set", async function () {
      await evmSort.setValue(100, true, true);
      expect(await evmSort.hasElement(100, true)).to.equal(true);

      await evmSort.setValue(100, false, true);
      expect(await evmSort.hasElement(100, true)).to.equal(false);
    });
  });

  describe("getMax", function () {
    it("Should return 0 for empty max set", async function () {
      expect(await evmSort.getMax()).to.equal(0);
    });

    it("Should return the maximum element", async function () {
      await evmSort.setValue(100, true, true);
      await evmSort.setValue(200, true, true);
      await evmSort.setValue(300, true, true);

      expect(await evmSort.getMax()).to.equal(300);
    });

    it("Should return correct max after adding larger element", async function () {
      await evmSort.setValue(100, true, true);
      expect(await evmSort.getMax()).to.equal(100);

      await evmSort.setValue(500, true, true);
      expect(await evmSort.getMax()).to.equal(500);
    });

    it("Should not remove element when calling getMax", async function () {
      await evmSort.setValue(100, true, true);
      await evmSort.getMax();

      expect(await evmSort.hasElement(100, true)).to.equal(true);
    });
  });

  describe("popMax", function () {
    it("Should revert when popping from empty max set", async function () {
      await expect(evmSort.popMax()).to.be.revertedWith("No elements available");
    });

    it("Should pop and return the maximum element", async function () {
      await evmSort.setValue(100, true, true);
      await evmSort.setValue(200, true, true);
      await evmSort.setValue(300, true, true);

      const maxValue = await evmSort.popMax.staticCall();
      expect(maxValue).to.equal(300);
    });

    it("Should remove element after popping", async function () {
      await evmSort.setValue(100, true, true);
      await evmSort.setValue(200, true, true);

      await evmSort.popMax();
      expect(await evmSort.hasElement(200, true)).to.equal(false);
      expect(await evmSort.getMax()).to.equal(100);
    });

    it("Should pop elements in descending order", async function () {
      await evmSort.setValue(50, true, true);
      await evmSort.setValue(150, true, true);
      await evmSort.setValue(100, true, true);
      await evmSort.setValue(200, true, true);

      expect(await evmSort.popMax.staticCall()).to.equal(200);
      await evmSort.popMax();
      expect(await evmSort.popMax.staticCall()).to.equal(150);
      await evmSort.popMax();
      expect(await evmSort.popMax.staticCall()).to.equal(100);
      await evmSort.popMax();
      expect(await evmSort.popMax.staticCall()).to.equal(50);
    });

    it("Should emit MaxValuePopped event", async function () {
      await evmSort.setValue(100, true, true);

      await expect(evmSort.popMax())
        .to.emit(evmSort, "MaxValuePopped")
        .withArgs(100);
    });
  });

  describe("removeSpecificMax", function () {
    it("Should revert when removing non-existent element", async function () {
      await expect(evmSort.removeSpecificMax(100)).to.be.revertedWith("Element not found");
    });

    it("Should remove specific element from max set", async function () {
      await evmSort.setValue(100, true, true);
      await evmSort.setValue(200, true, true);
      await evmSort.setValue(300, true, true);

      await evmSort.removeSpecificMax(200);

      expect(await evmSort.hasElement(200, true)).to.equal(false);
      expect(await evmSort.hasElement(100, true)).to.equal(true);
      expect(await evmSort.hasElement(300, true)).to.equal(true);
    });

    it("Should update max after removing current max", async function () {
      await evmSort.setValue(100, true, true);
      await evmSort.setValue(200, true, true);
      await evmSort.setValue(300, true, true);

      await evmSort.removeSpecificMax(300);
      expect(await evmSort.getMax()).to.equal(200);
    });
  });

  describe("Edge Cases - Max Set", function () {
    it("Should handle single element", async function () {
      await evmSort.setValue(42, true, true);
      expect(await evmSort.getMax()).to.equal(42);
      expect(await evmSort.popMax.staticCall()).to.equal(42);
      await evmSort.popMax();
      expect(await evmSort.getMax()).to.equal(0);
    });

    it("Should handle large numbers", async function () {
      const largeNum = ethers.toBigInt("1000000000000");
      await evmSort.setValue(largeNum, true, true);
      expect(await evmSort.getMax()).to.equal(largeNum);
    });

    it("Should handle adding same element twice", async function () {
      await evmSort.setValue(100, true, true);
      await evmSort.setValue(100, true, true);

      expect(await evmSort.hasElement(100, true)).to.equal(true);
      await evmSort.popMax();

      // Element should be removed after one pop
      expect(await evmSort.getMax()).to.equal(0);
    });

    it("Should handle consecutive values", async function () {
      await evmSort.setValue(1, true, true);
      await evmSort.setValue(2, true, true);
      await evmSort.setValue(3, true, true);

      expect(await evmSort.getMax()).to.equal(3);
      await evmSort.popMax();
      expect(await evmSort.getMax()).to.equal(2);
    });
  });
});
