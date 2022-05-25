// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VRFv2Consumer is VRFConsumerBaseV2, Ownable {

  using SafeMath for uint256;
  VRFCoordinatorV2Interface COORDINATOR;

  // Your subscription ID.
  uint64 s_subscriptionId;

  // Polygon Mumbai Testnet coordinator.
  address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
  bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
  uint32 callbackGasLimit = 100000;
  uint16 requestConfirmations = 2;


  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;
  uint32 numWords = 1;
  uint32 numbersInLottery = 5;


  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
  }

  // Assumes the subscription is funded sufficiently.
  // https://vrf.chain.link/mumbai
  function requestRandomness() public onlyOwner {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );

  }

  function makeLotteries(uint32 _seed) public view returns (uint32[] memory) {
    require(s_randomWords[0] != 0 , "not fulfill yet");

    uint256 randomNumber = uint256(keccak256(abi.encode(s_randomWords[0], _seed)));
    uint32[] memory lottery = new uint32[](numbersInLottery);
    for(uint32 j =0; j < numbersInLottery; j++) {
      uint32 num = uint32(randomNumber.mod(100));
      randomNumber = randomNumber.div(100);
      lottery[j] = num;
    }
    return lottery;
  }
    

  // fallback for requestRandomness
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
  }
}
