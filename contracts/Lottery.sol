// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./VRFv2Consumer.sol";

contract Lottery is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    struct Lotto {
        uint32[] lotto;
    }

    enum TimeLock {
        Open, Close
    }

    IERC20 token;
    VRFv2Consumer consumer;
    Lotto winningNumber;
    mapping(address => Lotto[]) lotteries;
    mapping(uint256 => address) public entries;
    uint32 numbersInLottery = 5;
    uint256 public totalLottery;
    uint256 decimal = 10 ** 18;
    TimeLock lock;

    //DAI mumbai : 0xcB1e72786A6eb3b44C2a2429e317c8a2462CFeb1
    constructor(address _vrfv2Interface, address _tokenAdderss) {
        consumer = VRFv2Consumer(_vrfv2Interface);
        token = IERC20(_tokenAdderss);
        totalLottery = 1;
        lock = TimeLock.Open;
    }

    function getLotteries(uint256 _amount) public Lock {
        token.safeTransferFrom(msg.sender, address(this), priceOfLotteries(_amount));

        if(lotteries[msg.sender].length == 0){
            entries[totalLottery] = msg.sender;
        }

        for(uint256 i=0; i< _amount; i++) {
            uint256 seed = i.add(uint256(uint160(msg.sender))).div(2);
            uint32[] memory ticket = consumer.makeLotteries(seed);
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

    function pickWinningNumber() public onlyOwner {
        uint32[] memory res = consumer.makeLotteries(uint256(block.timestamp));
        winningNumber = Lotto(res);
    }

    function getWinningNumber() public view returns (Lotto memory) {
        return winningNumber;
    }

    function pickWinners() public onlyOwner {
        for(uint256 i =1; i <totalLottery; i++) {

            address user = entries[i];
            Lotto[] memory lottos = lotteries[user];

            for (uint j =0; j < lottos.length; j++) {
                uint32 rank = getRank(lottos[j]);
                if(rank != 0) {
                    token.safeTransfer(user, prize(rank));
                }
            }

        }
    }

    function prize(uint32 _rank) public pure returns (uint256) {
        uint32 value;
        if (_rank == 1) value = 10000;
        else if (_rank == 2) value = 2000;
        else if (_rank == 3) value = 500;
        else if (_rank == 4) value = 10;
        else if (_rank == 5) value = 1;
        return value * 10 ** 18;
    }

    function priceOfLotteries(uint256 _amount) public view returns (uint256) {
        _amount = _amount.mul(decimal);
        _amount = _amount.div(4);
        return _amount;
    }

    function balanceOf(address _from) public view returns(uint256) {
        return token.balanceOf(_from);
    }

    function resetEntry() public onlyOwner {
        for(uint256 i = 1; i< totalLottery; i++) {
            address user = entries[i];
            delete lotteries[user];
            delete entries[i];
            totalLottery = 0;
        }
    }

    function setTimeLock(uint32 _bit) public onlyOwner {
        lock = (_bit == 0) ? TimeLock.Open : TimeLock.Close;
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

    modifier Lock {
        require(lock == TimeLock.Open, "Locked");
        _;
    }

}