// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "solidity-rlp/contracts/RLPReader.sol";
import "./ProvethVerifier.sol";

import "hardhat/console.sol";

contract Tester {
  using RLPReader for RLPReader.RLPItem;
  using RLPReader for RLPReader.Iterator;
  using RLPReader for bytes;

  function test() public pure {
    console.log("Hello, Hardhat!");
  }

  function rlpEncode(bytes memory data) public pure returns (bytes memory) {
    console.log("Input data");
    console.logBytes(data);
    return abi.encodePacked(data);
  }

  function inputTest(
    uint256 blockNumber,
    bytes memory rlpBlockHeader,
    bytes32 txHash,
    bytes memory rlpTxIndex,
    bytes memory rlpTxProof
  ) public pure {
    bytes32 blockHash = keccak256(rlpBlockHeader);
    console.log("blockHash: %s", bytes32ToHexString(blockHash));

    RLPReader.RLPItem[] memory blockHeaderItems = rlpBlockHeader.toRlpItem().toList();
    RLPReader.RLPItem memory transactionRootItem = blockHeaderItems[4];
    bytes32 transactionRoot = bytesToBytes32(transactionRootItem.toBytes());

    RLPReader.RLPItem[] memory txProofItems = rlpTxProof.toRlpItem().toList();
    bytes32 txRootFromProof = keccak256(txProofItems[0].toRlpBytes());
    if(transactionRoot == txRootFromProof) {
      console.log("Transaction root is correct");
      console.log("transactionRoot: %s", bytes32ToHexString(transactionRoot));
    } else {
      revert("Transaction root is incorrect");
    }

    bytes memory value = ProvethVerifier.validateMPTProof(
      transactionRoot,
      ProvethVerifier.decodeNibbles(rlpTxIndex, 0),
      txProofItems
    );
    console.log("value: %s", bytesToHexString(value));

    bytes32 txHashFromProof = keccak256(value);
    if(txHash == txHashFromProof) {
      console.log("Transaction hash is correct");
      console.log("txHash: %s", bytes32ToHexString(txHash));
    } else {
      revert("Transaction hash is incorrect");
    }

    RLPReader.Iterator memory iter = value.toRlpItem().iterator();
    console.log("Transaction");
    while(iter.hasNext()) {
      RLPReader.RLPItem memory item = iter.next();
      bytes memory txItem = item.toBytes();
      console.log(bytesToHexString(txItem));
    }
  }

  function bytesToBytes32(bytes memory data) public pure returns (bytes32) {
    require(data.length == 32, "Invalid data length");
    bytes32 result;
    assembly {
      result := mload(add(data, 32))
    }
    return result;
  }

  function bytes32ToHexString(bytes32 data) public pure returns (string memory) {
    bytes memory hexString = new bytes(64);
    for (uint256 i = 0; i < 32; i++) {
      uint8 byteValue = uint8(data[i]);
      uint8 highNibble = byteValue >> 4;
      uint8 lowNibble = byteValue & 0x0F;
      hexString[i * 2] = charToHex(highNibble);
      hexString[i * 2 + 1] = charToHex(lowNibble);
    }
    return string(hexString);
  }

  function bytesToHexString(bytes memory data) public pure returns (string memory) {
    bytes memory hexString = new bytes(data.length * 2);
    for (uint256 i = 0; i < data.length; i++) {
      uint8 byteValue = uint8(data[i]);
      uint8 highNibble = byteValue >> 4;
      uint8 lowNibble = byteValue & 0x0F;
      hexString[i * 2] = charToHex(highNibble);
      hexString[i * 2 + 1] = charToHex(lowNibble);
    }
    return string(hexString);
  }

  function charToHex(uint8 value) private pure returns (bytes1) {
    if (value < 10) {
      return bytes1(uint8(bytes1('0')) + value);
    } else {
      return bytes1(uint8(bytes1('a')) + (value - 10));
    }
  }
}