// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./VRFv2Consumer.sol";

contract Lottery is Ownable {
    using SafeMath for uint256;

    struct Lotto {
        uint32[] lotto;
    }

    IERC20 USDT;
    VRFv2Consumer consumer;
    mapping(address => Lotto[]) lotteries;
    mapping(uint256 => address) public entries;
    uint256 public totalLottery;
    Lotto winningNumber;
    uint32 numbersInLottery = 5;

    //using USDT mumbai : 0x3813e82e6f7098b9583FC0F33a962D02018B6803
    constructor(address _vrfv2Interface, address _usdtAdderss) {
        consumer = VRFv2Consumer(_vrfv2Interface);
        USDT = IERC20(_usdtAdderss);
        totalLottery = 1;
    }

    //if getting Lottery is first time, put address in entreis.
    // entries will use for picking winner.
    function getLotteries(uint32 _amount) public {
        
        if(lotteries[msg.sender].length == 0){
            entries[totalLottery] = msg.sender;
        }


        for(uint32 i=0; i< _amount; i++) {
            uint32[] memory ticket = consumer.makeLotteries(i);
            lotteries[msg.sender].push(Lotto(ticket));
        }
        totalLottery = totalLottery.add(_amount);
    }

    function amountOfLotto() public view returns (uint256) {
        return lotteries[msg.sender].length;
    }
    
    function getHavingLottos() public view returns (Lotto[] memory) {
        return lotteries[msg.sender];
    }

    // 5 => 1st prize
    // 4 => 2nd prize
    // 3 => 3rd prize
    // 2 => 4th prize
    // 1 => 5th prize
    function pickWinningNumber() public onlyOwner {
        uint32[] memory res = consumer.makeLotteries(uint32(block.timestamp));
        winningNumber = Lotto(res);
    }

    function getWinningNumber() public view returns (Lotto memory) {
        return winningNumber;
    }

    function getRank(Lotto memory _lottery) private view returns(uint32) {
        uint256 count = 0;
        for(uint32 i=0; i < numbersInLottery; i++) {

            if(winningNumber.lotto[i] == _lottery.lotto[i]){
                count = count.add(1);
            }

        }
        uint32 rank = uint32((count > 0 ) ? 6 - count : 0);
        return rank;
    }

    function pickWinners() public onlyOwner {
        for(uint256 i =1; i <totalLottery; i++) {

            address user = entries[i];
            Lotto[] memory lottos = lotteries[user];

            for (uint j =0; j < lottos.length; j++) {
                uint32 rank = getRank(lottos[j]);
                if(rank != 0) {
                    transfer(user, rank);
                }
            }

        }
    }

    function prize(uint32 _rank) public pure returns (uint32) {
        uint32 value;
        if (_rank == 1) value = 10000;
        else if (_rank == 2) value = 2000;
        else if (_rank == 3) value = 500;
        else if (_rank == 4) value = 10;
        else if (_rank == 5) value = 1;
        return value;
    }

    function transfer(address _to, uint32 _rank) public {
        uint amount = prize(_rank);
        require(USDT.balanceOf(address(this)) >= amount, "balance is not enough to giving prize");
        _transfer(_to, amount);
        
    }

    function _transfer(address _to, uint256 _amount) private {
        (bool success, bytes memory data) = address(USDT).call(abi.encodeWithSelector(bytes4(keccak256("transfer(address,uint)")), _to, _amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TF");

    }
}