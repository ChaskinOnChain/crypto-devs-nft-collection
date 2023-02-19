// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/CryptoDevs.sol";

contract DeployScript is Script {
    address public WHITELIST_CONTRACT_ADDRESS =
        0x44138c16D71a5AD2AA22DD9b9977174536E4dfb9;
    string public METADATA_URL =
        "https://nft-collection-sneh1999.vercel.app/api/";

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new CryptoDevs(METADATA_URL, WHITELIST_CONTRACT_ADDRESS);
        vm.stopBroadcast();
    }
}
