import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { getAddress, parseGwei } from "viem";

const { GetProof, VerifyProof } = require('eth-proof');
const { keccak, encode } = require('eth-util-lite');

describe("Tester", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployTesterFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await hre.viem.getWalletClients();

    const tester = await hre.viem.deployContract("Tester");

    const publicClient = await hre.viem.getPublicClient();

    return {
      tester,
      owner,
      otherAccount,
      publicClient,
    };
  }

  describe("Test", function () {
    // it("Test1", async function () {
    //   const { tester } = await loadFixture(deployTesterFixture);

    //   await tester.read.test();

    //   const buffer = Buffer.from([1]);
    //   const input = '0x'.concat(buffer.toString("hex")) as `0x${string}`;
    //   const res = await tester.read.rlpEncode([input]);
    //   console.log(res);
    // });

    it("Test2", async function () {
      const { tester } = await loadFixture(deployTesterFixture);

      const rpcUrl = "http://localhost:8000";
      const targetTxHash = "0xe1c8bd9351a7fea473b0e77b83869f6865afcc4bbfb35d05c95159d09ce1eec1";

      const getProof = new GetProof(rpcUrl);
      const res = await getProof.transactionProof(targetTxHash);
      const blockHash = VerifyProof.getBlockHashFromHeader(res.header);

      const blockNumberBuffer = res.header[8];
      const blockNumber: bigint = BigInt(`0x${blockNumberBuffer.toString("hex")}`);

      const txsRootBuffer = res.header[4];
      const txsRoot: `0x${string}` = `0x${txsRootBuffer.toString("hex")}`;

      const rlpBlockHeaderBuffer = encode(res.header);
      const rlpBlockHeader: `0x${string}` = `0x${rlpBlockHeaderBuffer.toString("hex")}`;

      const txHash: `0x${string}` = targetTxHash;

      const rlpTxIndexBuffer = encode(res.txIndex);
      const rlpTxIndex: `0x${string}` = `0x${rlpTxIndexBuffer.toString("hex")}`;

      const txProofs = res.txProof;
      let rlpTxProofs: Buffer[] = [];
      for (let i = 0; i < txProofs.length; i++) {
        const txProofElBuffer = encode(txProofs[i]);
        rlpTxProofs.push(txProofElBuffer);
      }
      const rlpTxProofBuffer = encode(res.txProof);
      const rlpTxProof: `0x${string}` = `0x${rlpTxProofBuffer.toString("hex")}`;

      await tester.read.inputTest([
        blockNumber,
        rlpBlockHeader,
        txHash,
        rlpTxIndex,
        rlpTxProof,
      ]);

      //console.log(res);
    });
  });
});
