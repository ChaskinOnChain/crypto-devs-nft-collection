// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./IWhitelist.sol";

contract CryptoDevs is ERC721Enumerable, Ownable {
    error PresaleNotStartedOrItsFinished();
    error NotWhitelisted();
    error ExceededMaxSupply();
    error DidntSendEnoughETH();
    error CurrentlyPresale();
    error TransferFailed();
    /**
     * @dev _baseTokenURI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    string public _baseTokenURI;
    uint256 public _price = 0.01 ether;
    bool public _paused;
    uint256 public maxTokenIds = 20;
    uint256 public tokenIds;
    IWhitelist public whitelist;
    bool public presaleStarted;
    uint256 public presaleEnded;

    modifier onlyWhenNotPaused() {
        require(!_paused, "Contract currently paused");
        _;
    }

    constructor(string memory baseURI, address whitelistContract)
        ERC721("Crypto Devs", "CD")
    {
        _baseTokenURI = baseURI;
        whitelist = IWhitelist(whitelistContract);
    }

    function startPresale() public onlyOwner {
        presaleStarted = true;
        presaleEnded = block.timestamp + 5 minutes;
    }

    function presaleMint() public payable onlyWhenNotPaused {
        if (!presaleStarted || block.timestamp > presaleEnded)
            revert PresaleNotStartedOrItsFinished();
        if (!whitelist.whitelistedAddresses(msg.sender))
            revert NotWhitelisted();
        if (tokenIds > maxTokenIds) revert ExceededMaxSupply();
        if (msg.value < _price) revert DidntSendEnoughETH();
        tokenIds += 1;
        //_safeMint is a safer version of the _mint function as it ensures that
        // if the address being minted to is a contract, then it knows how to deal with ERC721 tokens
        // If the address being minted to is not a contract, it works the same way as _mint
        _safeMint(msg.sender, tokenIds);
    }

    function mint() public payable onlyWhenNotPaused {
        if (presaleStarted && block.timestamp <= presaleEnded)
            revert CurrentlyPresale();
        if (tokenIds >= maxTokenIds) revert ExceededMaxSupply();
        if (msg.value < _price) revert DidntSendEnoughETH();
        tokenIds += 1;
        _safeMint(msg.sender, tokenIds);
    }

    /**
     * @dev _baseURI overides the Openzeppelin's ERC721 implementation which by default
     * returned an empty string for the baseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setPaused(bool val) public onlyOwner {
        _paused = val;
    }

    /**
     * @dev withdraw sends all the ether in the contract
     * to the owner of the contract
     */
    function withdraw() public onlyOwner {
        address _owner = owner();
        (bool sent, ) = _owner.call{value: address(this).balance}("");
        if (!sent) revert TransferFailed();
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
