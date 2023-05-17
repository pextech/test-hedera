// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

interface INFT {

  struct NFT {
    uint256 id;
    string tokenURI;
    string metadataURI;
    uint256 idOfCollection;
    string name;
    string image;
    bytes32 ipfsHash;
    int64 tokenId;
    address collectionAddress;
    uint256 cBalance;
    address ownerAddress;

  }

  event mintedAnNft(address collectionAddress, uint256 tokenId);

}