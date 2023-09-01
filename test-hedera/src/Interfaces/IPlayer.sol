// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

interface IPlayer {

    struct Player {
        uint256 id;
        address playerAddress;
        string name;
        bool active;
        bool reedemed;
        string username;
        string email;
        string twitter;
        string discord;
        string telegram;
    }

    function setPlayer(string memory _name, address playerAddress, string memory username, string memory email, string memory twitter, string memory discord, string memory telegram) external returns (Player memory);
    function updatePlayer(address playerAddress, string memory username, string memory email, string memory twitter, string memory discord, string memory telegram) external returns(Player memory);


}
