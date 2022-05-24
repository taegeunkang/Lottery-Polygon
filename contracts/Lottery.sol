// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./VRFv2Consumer.sol";

contract Lottery is Ownable {
    using SafeMath for uint256;
    VRFv2Consumer consumer;

    mapping(address => uint32[][]) public lotteries;
    uint256 public totalLottery;
    constructor(address _vrfv2Interface) {
        consumer = VRFv2Consumer(_vrfv2Interface);
        totalLottery = 0;
    }

    function getTickets(uint32 _amount) external {
        for(uint32 i=0; i< _amount; i++) {
            uint32[] memory ticket = consumer.makeTickets(i);
            lotteries[msg.sender].push(ticket);
        }
        totalLottery = totalLottery.add(_amount);
    }
}