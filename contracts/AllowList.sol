//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AllowList {

    bytes32 public presaleRoot;
    bytes32 public whitelistRoot;
    address public owner;

    constructor(bytes32 _presaleRoot, bytes32 _whitelistRoot) {
        owner = msg.sender;
        presaleRoot = _presaleRoot;
        whitelistRoot = _whitelistRoot;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You can't do that");
        _;
    }

    function isPresale(bytes32[] calldata merkleProof) external view returns (bool) {

        bytes32 leaf = keccak256(abi.encodePacked((msg.sender)));
        
        return MerkleProof.verify(merkleProof, presaleRoot, leaf);
    }

    function isWhitelist(bytes32[] calldata merkleProof) external view returns (bool) {

        bytes32 leaf = keccak256(abi.encodePacked((msg.sender)));
        
        return MerkleProof.verify(merkleProof, whitelistRoot, leaf);
    }

    function updatePresaleRoot(bytes32 _presaleRoot) external onlyOwner {
        presaleRoot = _presaleRoot;
    }

    function updateWhitelistRoot(bytes32 _whitelistRoot) external onlyOwner {
        whitelistRoot = _whitelistRoot;
    }
}