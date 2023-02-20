// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/CryptoDevs.sol";

contract DeployScript is Script {
    address public WHITELIST_CONTRACT_ADDRESS =
        0x700b6A60ce7EaaEA56F065753d8dcB9653dbAD35;
    string public METADATA_URL =
        "https://nft-collection-sneh1999.vercel.app/api/";

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        new CryptoDevs(METADATA_URL, WHITELIST_CONTRACT_ADDRESS);
        vm.stopBroadcast();
    }
}

// 0xa15bb66138824a1c7167f5e85b957d04dd34e468
