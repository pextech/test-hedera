// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;


interface ICollection {


enum tier {
    GOLD,
    SILVER,
    BLONZE
}

    struct Collection {
        uint256 id;
        address collectionAddress;
        bool active;
        string name;
        string symbol;
        uint256 nfts;
        tier nftTier;
    }

    event CollectionCreated(string _name, string _symbol, uint256 _nfts,bool _active, address _collectionAddress);

    function allCollections() external view returns (Collection[] memory);


}