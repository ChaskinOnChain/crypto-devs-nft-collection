// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CryptoDevs.sol";
import "../src/Whitelist.sol";

contract CounterTest is Test {
    WhiteList public whiteList;
    CryptoDevs public cryptoDevs;
    address public alice = address(0x123);

    function setUp() public {
        whiteList = new WhiteList(5);
        cryptoDevs = new CryptoDevs(
            "https://nft-collection-sneh1999.vercel.app/api/",
            address(whiteList)
        );
    }

    function testSetUp() public {
        assertEq(
            cryptoDevs._baseTokenURI(),
            "https://nft-collection-sneh1999.vercel.app/api/"
        );
        assertEq(address(cryptoDevs.whitelist()), address(whiteList));
    }

    function testStartPresale() public {
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        cryptoDevs.startPresale();
        vm.stopPrank();
        cryptoDevs.startPresale();
        assertEq(cryptoDevs.presaleStarted(), true);
        assertEq(cryptoDevs.presaleEnded(), block.timestamp + 5 minutes);
    }

    function testPresaleMint() public {
        // Test pause
        cryptoDevs.setPaused(true);
        vm.expectRevert("Contract currently paused");
        cryptoDevs.presaleMint();
        cryptoDevs.setPaused(false);
        // presale not started
        vm.expectRevert(CryptoDevs.PresaleNotStartedOrItsFinished.selector);
        cryptoDevs.presaleMint();
        // not whitelisted
        cryptoDevs.startPresale();
        vm.expectRevert(CryptoDevs.NotWhitelisted.selector);
        cryptoDevs.presaleMint();
        // presale ended
        cryptoDevs.startPresale();
        vm.startPrank(alice);
        deal(alice, 100 ether);
        whiteList.addAddressToWhitelist();
        skip(301);
        vm.expectRevert(CryptoDevs.PresaleNotStartedOrItsFinished.selector);
        cryptoDevs.presaleMint{value: 0.01 ether}();
        vm.stopPrank();
        rewind(301);
        // didn't send enough eth
        cryptoDevs.startPresale();
        vm.startPrank(alice);
        vm.expectRevert(CryptoDevs.DidntSendEnoughETH.selector);
        cryptoDevs.presaleMint{value: 0.005 ether}();
        vm.stopPrank();
        // should pass
        vm.startPrank(alice);
        deal(alice, 100 ether);
        cryptoDevs.presaleMint{value: 0.01 ether}();
        assertEq(cryptoDevs.tokenIds(), 1);
    }

    function testMint() public {
        cryptoDevs.startPresale();
        vm.startPrank(alice);
        deal(alice, 100 ether);
        // still presale
        vm.expectRevert(CryptoDevs.CurrentlyPresale.selector);
        cryptoDevs.mint{value: 0.01 ether}();
        // didn't send enough ETH
        skip(301);
        vm.expectRevert(CryptoDevs.DidntSendEnoughETH.selector);
        cryptoDevs.mint{value: 0.005 ether}();
        // should fail after 20
        for (uint256 i = 1; i < 22; i++) {
            if (i == 21) {
                vm.expectRevert(CryptoDevs.ExceededMaxSupply.selector);
                cryptoDevs.mint{value: 0.01 ether}();
            } else {
                cryptoDevs.mint{value: 0.01 ether}();
                assertEq(cryptoDevs.tokenIds(), i);
            }
        }
    }
}
