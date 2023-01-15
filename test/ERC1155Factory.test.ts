import { expect, assert } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ERC1155Factory, ERC1155Factory__factory } from "../typechain-types";

describe("ERC1155Factory Contract", () => {
  let erc1155Factory: ERC1155Factory;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;

  beforeEach(async () => {
    [owner, addr1, addr2] = await ethers.getSigners();

    let erc1155Factory_factory = await ethers.getContractFactory(
      "ERC1155Factory",
      owner
    );

    erc1155Factory = await erc1155Factory_factory.deploy();
  });

  describe("Verify Deployment", () => {
    it("should expect the deployment address", async () => {
      assert(erc1155Factory.address);
    });
  });

  describe("Factory Initialization", () => {
    it("Should initialize ERC1155 Factory Contract", async () => {
      const name = "DiamondNXT ERC1155 Factory";
      const symbol = "DNXT";
      await erc1155Factory.connect(owner).initialize(name, symbol);
      expect(await erc1155Factory.name()).to.equal(name);
      expect(await erc1155Factory.symbol()).to.equal(symbol);
    });
  });

  describe("Create ERC1155 Collection", () => {
    it("should create an erc1155 collection", async () => {
      const name = "RoboCop";
      const symbol = "RC";

      const tx = await erc1155Factory
        .connect(addr1)
        .createCollection(name, symbol, addr1.address);
      const res = await tx.wait();

      if (res.events && res.events[1] && res.events[1].args) {
        expect(res.events && res.events[1].event).to.equal(
          "ERC1155CollectionCreated"
        );

        const collectionAddress = res.events && res.events[1].args.collection;

        const collection = await ethers.getContractAt(
          "ERC1155Asset",
          collectionAddress
        );

        expect(await erc1155Factory.createdCollections(collectionAddress)).to.be
          .true;

        expect(await collection.name()).to.equal(name);
        expect(await collection.symbol()).to.equal(symbol);
        expect(await collection.totalMinted()).to.equal(0);
      }
    });

    it("Should create an nft collection and mint an nft", async () => {
      const name = "RoboCop";
      const symbol = "RC";

      const token = {
        to: addr1.address,
        tokenId: 10,
        amount: 5,
        metadataUri: `ipfs://token-22`,
      };

      const tx = await erc1155Factory
        .connect(addr1)
        .createCollection(name, symbol, addr1.address);
      const res = await tx.wait();

      if (res.events && res.events[1] && res.events[1].args) {
        expect(res.events && res.events[1].event).to.equal(
          "ERC1155CollectionCreated"
        );

        const collectionAddress = res.events && res.events[1].args.collection;

        expect(await erc1155Factory.createdCollections(collectionAddress)).to.be
          .true;

        const collection = await ethers.getContractAt(
          "ERC1155Asset",
          collectionAddress
        );

        expect(await collection.name()).to.equal(name);
        expect(await collection.symbol()).to.equal(symbol);
        expect(await collection.owner()).to.equal(addr1.address);
        expect(await collection.totalMinted()).to.equal(0);

        await erc1155Factory
          .connect(addr1)
          .createItem(collectionAddress, token);

        expect(await collection.exists(token.tokenId)).to.equal(true);
        expect(await collection.minterOf(token.tokenId)).to.equal(
          addr1.address
        );
        expect(await collection.uri(token.tokenId)).to.equal(token.metadataUri);
      }
    });
  });

  describe("Error checks", () => {
    it("Should allow only owner to pause contract", async () => {
      expect(await erc1155Factory.paused()).to.be.false;

      await expect(erc1155Factory.connect(addr2).pause()).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );

      await erc1155Factory.connect(owner).pause();

      expect(await erc1155Factory.paused()).to.be.true;
    });

    it("Should revert when paused", async () => {
      const name = "RoboCopCollection #3";
      const symbol = "RC";

      await erc1155Factory.connect(owner).pause();

      await expect(
        erc1155Factory
          .connect(addr2)
          .createCollection(name, symbol, addr2.address)
      ).to.be.revertedWith("Pausable: paused");
    });
  });
});
