import { expect, assert } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { ERC1155Factory__factory, ERC1155Factory } from "../typechain-types";

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

  describe("Initialization", () => {
    it("Should initialize ERC1155 Factory Contract", async () => {
        const name = "DiamondNXT SFT Factory";
        await erc1155Factory.initialize(name, );
    });
  });
});
