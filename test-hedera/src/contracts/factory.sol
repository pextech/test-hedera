// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFT.sol";
import "./openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ICollection } from "../Interfaces/ICollection.sol";
import { INFT } from "../Interfaces/INfts.sol";
import { Counters } from "./openzeppelin/contracts/utils/Counters.sol";
import "./HederaTokenService.sol";
import "./openzeppelin/contracts/utils/math/SafeMath.sol";
import { IStake } from "../Interfaces/IStake.sol";

contract testNFT is INFT, ICollection, ReentrancyGuard, IStake, HederaTokenService {
    using Counters for Counters.Counter;

    Counters.Counter public goldSupply;
    Counters.Counter public silverSupply;
    Counters.Counter public bronzeSupply;
    Counters.Counter public collectionCount;
    Counters.Counter public nftsCount;

     using SafeMath for uint256;

    mapping (uint256 => Collection) public _collections;
    mapping (uint256 => NFT) public _nfts;
    mapping(address => uint) public tokenId;
    mapping(bytes32 => bool) private _ipfsHashes;
    mapping(address => mapping(uint256 => uint256)) public balances;
    mapping (address => mapping(uint256 => Stake)) public stakes;

    uint256 public totalStaked;
    int64 public totalRewards;

    address public CardAddress = 0x0000000000000000000000000000000000a1e695;

    constructor(){
    }

    function createCollection (string memory _name, string memory _symbol, address collectionAddress, tier nftTier) public returns (Collection memory){
        Collection memory collection;

        collectionCount.increment();
        collection.id = collectionCount.current();
        collection.name = _name;
        collection.symbol = _symbol;
        collection.nfts = 0;
        collection.active = true;
        collection.collectionAddress = collectionAddress;
        _collections[collectionCount.current()] = collection;
        collection.nftTier = nftTier;

        emit CollectionCreated(_name, _symbol, 0, true, collectionAddress);

        return collection;
    }

    function allCollections() public view override returns (Collection[] memory){
        uint256 collectionIndex = 0;

        Collection[] memory CollectionArray = new Collection[](collectionCount.current());

        for (uint256 i = 0; i < collectionCount.current(); i++) {
                uint256 currentCollectionId = i + 1;
                Collection storage currentCollection = _collections[currentCollectionId];
                CollectionArray[collectionIndex] = currentCollection;
                collectionIndex += 1;
        }
        return CollectionArray;
    }

    function mintNFT(uint256 collectionId, address collectionAddress, bytes[] memory metadata, string memory _tokenURI) public returns(uint){
        NFT memory nft;

        nftsCount.increment();
        nft.id = nftsCount.current();
        nft.idOfCollection = collectionId;
        nft.tokenURI = _tokenURI;
        nft.collectionAddress = collectionAddress;
        nft.ownerAddress = msg.sender;
        (
            int256 response,
            uint64 newTotalSupply,
            int64[] memory serialNumbers
        ) = HederaTokenService.mintToken(collectionAddress, 0, metadata);

        if(response != HederaResponseCodes.SUCCESS){
            revert("Failed to mint non-fungible token");
        }

        nft.tokenId = serialNumbers[0];
        _nfts[nftsCount.current()] = nft;

        _collections[collectionId].nfts += 1;

        return newTotalSupply;
    } 

    function burnToken(uint256 nftId) public returns(uint64) {
        NFT memory nft = _nfts[nftId];
        require(nft.ownerAddress == msg.sender, "Caller not owner");
        Collection memory nftCollection = _collections[nft.idOfCollection];

        int64[] memory serialNumber;
        serialNumber[0] = nft.tokenId;

        (
            int256 response,
            uint64 newTotalSupply
        ) = HederaTokenService.burnToken(_collections[nft.idOfCollection].collectionAddress, 0, serialNumber);
        if(response != HederaResponseCodes.SUCCESS){
            revert("Failed to burn non-fungible token");
        }

        nftCollection.nfts -= 1;

        if(nftCollection.nftTier == tier.GOLD){
            goldSupply.decrement();
        }
        if(nftCollection.nftTier == tier.BLONZE){
            bronzeSupply.decrement();
        }
        if(nftCollection.nftTier == tier.SILVER){
            silverSupply.decrement();
        }

        return newTotalSupply;
    }

    function mintGold(bytes[] memory metadata, string memory _tokenURI, address collectionAddress) public {
        require(goldSupply.current() < 20, "Gold tier has reached maximum supply");
        Collection memory newCollection = createCollection("Gold NFT Tier", "GNT", collectionAddress, tier.GOLD);

        mintNFT(newCollection.id, collectionAddress, metadata, _tokenURI);
        goldSupply.increment();
    }

    function mintSilver(bytes[] memory metadata, string memory _tokenURI, address collectionAddress) public {
        require(silverSupply.current() < 30, "Silver tier has reached maximum supply");
        Collection memory newCollection = createCollection("Silver NFT Tier", "SNT", collectionAddress, tier.SILVER);

        mintNFT(newCollection.id, collectionAddress, metadata, _tokenURI);
        silverSupply.increment();
    }

    function mintBronze(bytes[] memory metadata, string memory _tokenURI, address collectionAddress) public {
        require(bronzeSupply.current() < 50, "Bronze tier has reached maximum supply");
        Collection memory newCollection = createCollection("Silver NFT Tier", "SNT", collectionAddress, tier.BLONZE);

        mintNFT(newCollection.id, collectionAddress, metadata, _tokenURI);
        bronzeSupply.increment();
    }

    function stake(uint256 _duration, uint256 nftId) external {
        require(_duration == 60 || _duration == 90 || _duration == 120, "Invalid duration");
        NFT memory nft = _nfts[nftId];
        require(nft.ownerAddress == msg.sender, "Caller not owner");
        Collection memory nftCollection = _collections[nft.idOfCollection];

        Stake storage stakeData = stakes[nftCollection.collectionAddress][nftId];
        require(!stakeData.staked, "Already staked");

        int64 reward = getReward(_duration);
        int64 penalty = 50;

         (
            int256 response
        ) = HederaTokenService.transferNFT(nftCollection.collectionAddress, nft.ownerAddress, address(this), nft.tokenId);

        if(response != HederaResponseCodes.SUCCESS){
            revert("Failed to stake non-fungible token");
        }

        stakeData.startTime = block.timestamp;
        stakeData.duration = _duration;
        stakeData.reward = reward;
        stakeData.penalty = penalty;
        stakeData.balance = 0;
        stakeData.staked = true;
        stakeData.claimed = false;

        totalStaked += 1;

        emit Staked(msg.sender, _duration);
    }

    function unstake(uint256 nftId) external {
        NFT memory nft = _nfts[nftId];
        require(nft.ownerAddress == msg.sender, "Caller not owner");
        Collection memory nftCollection = _collections[nft.idOfCollection];

        Stake storage stakeData = stakes[nftCollection.collectionAddress][nftId];
        require(stakeData.staked, "Not staked");

        uint256 endTime = stakeData.startTime.add(stakeData.duration);
        int64 penalty = 0;

        if (block.timestamp < endTime) {
            penalty = stakeData.penalty;
             (
            int256 response
            ) = HederaTokenService.transferToken(CardAddress, nft.ownerAddress, address(this), penalty);

            if(response != HederaResponseCodes.SUCCESS){
                revert("Failed to transfer C tokens");
            }
        }

        stakeData.balance = 0;
        totalStaked -= 1;

        if (stakeData.claimed == false) {
            int64 reward = stakeData.reward - penalty;
            (
            int256 response
            ) = HederaTokenService.transferToken(CardAddress, nft.ownerAddress, address(this), penalty);

            if(response != HederaResponseCodes.SUCCESS){
                revert("Failed to transfer C tokens");
            }

            stakeData.claimed = true;
            totalRewards += reward;
            emit RewardClaimed(msg.sender, reward);
        }

        emit Unstaked(msg.sender);
    }

    function getReward(uint256 _duration) public pure returns (int64) {
        if (_duration == 60) {
            return 10;
        } else if (_duration == 90) {
            return 20;
        } else if (_duration == 120) {
            return 30;
        } else {
            return 0;
        }
    }
}