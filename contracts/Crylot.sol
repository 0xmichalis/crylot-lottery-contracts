// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from '@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol';
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Crylot is VRFConsumerBaseV2Plus {
    // ---------- CHAINLINK VRF SETTINGS ----------
    bytes32 immutable public keyHash;
    uint32 constant public callbackGasLimit = 100000;
    uint16 constant public requestConfirmations = 3;
    uint32 constant public numWords = 1;
    uint256 immutable public s_subscriptionId;

    // ----------  BET SETTINGS ----------
    event BetDone();
    event NumberGuessed(address _addr, bool guessed, uint256 number, uint256 winningNumber);
    event WithdrawnUserFunds(address _addr, uint256 funds);
    event WithdrawnBalance(address _addr, uint256 quantity);

    uint256 minBet = 0.001 ether;
    uint256 maxBet = 0.1 ether;
    uint256 totalBets = 0;

    bool isPaused = false;

    mapping(address => uint256) userFunds;
    mapping(address => uint256) userBets;

    // -/ SET GAME DIFFICULTIES \-
    // categorie => reward
    // BRONZE - EMERALD - DIAMOND
    uint256[3] categories = [7, 35, 70];
    uint256[3] range = [10, 50, 100];

    constructor(bytes32 _keyHash, address _vrfCoordinator, uint256 subscriptionId)
        VRFConsumerBaseV2Plus(_vrfCoordinator)
    {
        s_subscriptionId = subscriptionId;
        keyHash = _keyHash;
    }

    struct Bet {
        uint256[] vrfNumber;
        bool fulfilled; // whether the request has been successfully fulfilled
        address _addr;
        uint256 amount;
        uint256 number;
        uint256 category;
    }
    mapping(uint256 => Bet) public bets; /* requestId --> requestStatus */

    function fulfillRandomWords(uint256 _betId, uint256[] calldata _randomWords) internal override {
        bets[_betId].fulfilled = true;
        bets[_betId].vrfNumber = _randomWords;

        //BET SETTINGS
        Bet memory req = bets[_betId];
        uint256 randomNumber = _randomWords[0] % range[req.category];
        if(req.number == randomNumber){
            userFunds[req._addr] += (req.amount * categories[req.category]);
        }
        emit NumberGuessed(req._addr, req.number == randomNumber, req.number, randomNumber);
        emit BetDone();
    }

    modifier onlyAdmin() {
        require(
            msg.sender == owner(),
            "You are not an admin"
        );
        _;
    }

    modifier canPlay() {
        require(
            isPaused == false,
            "The game is paused"
        );
        _;
    }

    bool internal locked;
    modifier noReentrancy() {
        require(!locked, "No re-entrancy!");
        locked = true;
        _;
        locked = false;
    }

    function bet(uint256 number, uint256 category) external payable canPlay returns(uint256 betId){
        require(category < 3 , "The categorie must be lower than 3");
        require(msg.value >= minBet, "The bet must be higher or equal than min bet");
        require(msg.value <= maxBet, "The bet must be lower or equal than max bet");

        betId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        // TODO: likely switch to native payments
                        nativePayment: false
                    })
                )
            })
        );
        bets[betId] = Bet(new uint256[](0), false, msg.sender, msg.value, number, category);

        userBets[msg.sender] += 1;
        totalBets += 1;

        return betId;
    }


    function getTotalBets() public view  returns (uint256) {
        return totalBets;
    }

    function getUserBets(address _addr) public view  returns (uint256) {
        return userBets[_addr];
    }

    function getMinBet() public view  returns (uint256) {
        return minBet;
    }

    function setMinBet(uint256 _newMinimum) public onlyAdmin returns (uint256) {
        require(_newMinimum > 0, "The minimum bet must be higher than 0");
        minBet = _newMinimum;
        return minBet;
    }

    function getMaxBet() public view returns (uint256) {
        return maxBet;
    }

    function setMaxBet(uint256 _newMaximum) public onlyAdmin returns (uint256) {
        require(_newMaximum > minBet, "The maximum bet must be higher than the minimum bet");
        maxBet = _newMaximum;
        return maxBet;
    }

    function isInPause() public view returns (bool) {
        return isPaused;
    }
    function setPaused(bool pause) public onlyOwner {
        isPaused = pause;
    }

    function getFunds(address _addr) public view returns (uint256) {
        return userFunds[_addr];
    }

    function withdrawUserFunds() public payable noReentrancy {
        uint256 funds = userFunds[msg.sender];
        require(getBalance() > funds, "The contract has no liquidity");
        require(funds > 0, "You do not have any funds");

        (bool success,) = (msg.sender).call{value:funds}("");
        require(success, "Transaction failed");

        userFunds[msg.sender] = 0;
        emit WithdrawnUserFunds(msg.sender, funds);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(address _addr) public payable onlyAdmin {
        uint256 balance = getBalance();
        require(balance > 0, "The balance is 0");
        (bool success,) = (_addr).call{value:balance}("");
        require(success, "Transaction failed");
        emit WithdrawnBalance(msg.sender, balance);
    }
}
