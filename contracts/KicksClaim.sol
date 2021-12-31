// SPDX-License-Identifier: NONE

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ShoeheadsToken.sol";
import "./Shoeheads.sol";

contract KicksClaim is Ownable, ReentrancyGuard {
    struct Tracker {
        uint256 tokenId;
        uint80 lastClaimed;
    }

    bool started;

    uint256 constant DAILY_RATE = 5 ether;
    
    Shoeheads public shoeheads;
    ShoeheadsToken public shoeheadsToken;
    
    mapping(uint256 => bool) public soles;
    mapping(uint256 => Tracker) public claimableSoles;

    constructor(address _erc721Addr, address _erc20Addr) {
        shoeheads = Shoeheads(_erc721Addr);
        shoeheadsToken = ShoeheadsToken(_erc20Addr);
        started = false;
    } 

    modifier _isStarted() {
        require(started, "Kicks token hasn't started yet");
        _;
    }

    function setERC20Address(address _erc20Addr) public onlyOwner {
        shoeheadsToken = ShoeheadsToken(_erc20Addr);
    }

    function setERC721Address(address _erc721Addr) public onlyOwner {
        shoeheads = Shoeheads(_erc721Addr);
    }

    function toggleStart() public onlyOwner {
        started = !started;
    }

    function addToCollection(uint256[] calldata _tokens) external onlyOwner {
        for (uint256 i; i < _tokens.length; i++) {
            Tracker memory tracker = Tracker(_tokens[i], uint80(block.timestamp));

            soles[_tokens[i]] = true;
            claimableSoles[_tokens[i]] = tracker;
        }
    }

    function claimKicks(uint256[] calldata _tokenIds) external _isStarted nonReentrant {
        uint256 rewards;

        for (uint256 i; i < _tokenIds.length; i++) {
            require(soles[_tokenIds[i]] == true, "Not part of the Sole Collection");
            require(shoeheads.ownerOf(_tokenIds[i]) == msg.sender, "No yo kicks");

            rewards += _calculateRewards(claimableSoles[_tokenIds[i]].lastClaimed);

            claimableSoles[_tokenIds[i]].lastClaimed = uint80(block.timestamp);
        }

        shoeheadsToken.mint(msg.sender, rewards);
    }

    function _calculateRewards(uint256 lastClaimed) internal view returns (uint256){
        require((uint80(block.timestamp) - lastClaimed) > 86400, "Can only claim every 24 hours");

        return uint256(((uint80(block.timestamp) - lastClaimed) / 86400) * DAILY_RATE);
    }
}