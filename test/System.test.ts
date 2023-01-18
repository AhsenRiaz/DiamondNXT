import { expect, assert } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Marketplace, ERC1155Asset, ERC1155Factory } from "../typechain-types";
import { Token } from "./utils";

describe("Testing the system", () => {
  let erc1155Factory: ERC1155Factory;
  let marketplace: Marketplace;
  //   let erc1155Asset: ERC1155Asset;

  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;

  let token: Token;
  let tokensBatch: ERC1155Factory.Erc1155MintDataBatchStruct;

  beforeEach(async () => {
    [owner, addr1, addr2] = await ethers.getSigners();

    let erc1155Factory_factory = await ethers.getContractFactory(
      "ERC1155Factory",
      owner
    );

    erc1155Factory = await erc1155Factory_factory.deploy();

    let marketplace_factory = await ethers.getContractFactory(
      "Marketplace",
      owner
    );

    marketplace = await marketplace_factory.deploy(
      [owner.address],
      ethers.utils.parseEther("1")
    );
  });

  describe("Verify Deployment", () => {
    it("should expect the deployment address of marketplace contract", async () => {
      assert(marketplace.address);
      assert((await marketplace.owner()) == owner.address);
    });
    it("should expect the deployment address of erc1155 factory contract", async () => {
      assert(erc1155Factory.address);
      assert((await erc1155Factory.owner()) == owner.address);
    });
  });

  describe("ERC1155 Factory", () => {
    it("should initialize the contract ", async () => {
      let name = "DiamondNXT Factory";
      let symbol = "DNXTF";
      await erc1155Factory.initialize(name, symbol);

      expect(await erc1155Factory.name()).to.eq(name);
      expect(await erc1155Factory.symbol()).to.eq(symbol);
    });
  });

  describe("ERC1155 Collection  ", () => {
    token = {
      to: "",
      tokenId: 3,
      amount: 2,
      metadataUri: "https://ipfs/token/3",
    };
    it("should creat an erc1155 asset collection and create token", async () => {
      let name = "RoboCop Collectioin";
      let symbol = "RC";
      token.to = addr1.address;

      let tx = await erc1155Factory
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

        expect(await collection.owner()).to.eq(addr1.address);

        await collection
          .connect(addr1)
          .setCollaborator(erc1155Factory.address, true);

        expect(await collection.isAccountCollaborator(erc1155Factory.address))
          .to.be.true;

        await erc1155Factory
          .connect(addr1)
          .createItem(collection.address, token);

        expect(await collection.balanceOf(token.to, token.tokenId)).to.eq(
          token.amount
        );
        expect(await collection.totalSupply(token.tokenId)).to.eq("2");
      }
    });

    it("should create an erc1155 asset collection and create batch items", async () => {
      let name = "RoboCop Collectioin";
      let symbol = "RC";

      tokensBatch = {
        to: addr1.address,
        tokenIds: [1, 2, 3],
        amounts: [5, 10, 15],
        metadataUris: ["https://ipfs/1", "https://ipfs/2", "https://ipfs/3"],
      };

      let tx = await erc1155Factory
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

        expect(await collection.owner()).to.eq(addr1.address);

        await collection
          .connect(addr1)
          .setCollaborator(erc1155Factory.address, true);

        expect(await collection.isAccountCollaborator(erc1155Factory.address))
          .to.be.true;

        await erc1155Factory
          .connect(addr1)
          .createItemBatch(collection.address, tokensBatch);

        for (var i = 0; i < tokensBatch.tokenIds.length; i++) {
          expect(
            await collection.balanceOf(tokensBatch.to, tokensBatch.tokenIds[i])
          ).to.eq(tokensBatch.amounts[i]);

          expect(await collection.totalSupply(tokensBatch.tokenIds[i])).to.eq(
            tokensBatch.amounts[i]
          );
        }
      }
    });
  });
});
