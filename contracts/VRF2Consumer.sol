// SPDX-License-Identifier: None
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract VRFv2Consumer is VRFConsumerBaseV2 {

  using SafeMath for uint256;
  VRFCoordinatorV2Interface COORDINATOR;

  // Your subscription ID.
  uint64 s_subscriptionId;

  // Polygon Mumbai Testnet coordinator.
  address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
  bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
  uint32 callbackGasLimit = 100000;
  uint16 requestConfirmations = 3;


  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;
  uint32 numWords = 1;
  uint32 numbers_in_lottery = 5;

 

  mapping(address => uint32[][]) public entries;


  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomness() public {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );

  }
  // this makes lottery tickets(composite of 5 numbers) with s_randomWords created by calling requestRandomness
  // but fullfilling randomewords require more time after transaction confirmed about requestRandomness()
  // so keep requesting for return tickets at frontend.
  function makeTickets(uint256 _amount) public {
    for (uint256 i = 0; i < _amount; i++) {
        uint256 randomNumber = uint256(keccak256(abi.encode(s_randomWords[0], i)));
        uint32[] memory lottery = new uint32[](numbers_in_lottery);

        for(uint32 j =0; j < numbers_in_lottery; j++) {
          uint32 num = uint32(randomNumber.mod(100));
          randomNumber = randomNumber.div(100);

          lottery[j] = num;
        }
        entries[msg.sender].push(lottery);
    }

  }

  
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
  }



  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}
