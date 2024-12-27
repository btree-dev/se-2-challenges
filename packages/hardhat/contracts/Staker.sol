// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  mapping ( address => uint256 ) public balances;

  uint256 public constant threshold = 10 ether;

  event Stake(address indexed staker, uint256 amount);

  uint256 public deadline = block.timestamp + 72 hours;

  bool public openForWithdraw;
  bool public openForDeposit = true;

  modifier onlyBeforeStaking() {
      bool stakeCompleted = exampleExternalContract.completed();
      require(stakeCompleted == false, "Staking is completed");
      _;
  }

  modifier onlyBeforeThreshold() {
      require(block.timestamp < deadline, "Deadline has passed");
      _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)

  function stake() public payable onlyBeforeThreshold {
    require(msg.value > 0, "Must send ETH to stake");
    require(openForDeposit, "Deposit is not open");
    console.log("Staking %s wei", msg.value);
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`

  function execute() public onlyBeforeStaking {
    require(block.timestamp >= deadline, "Deadline has not passed");
    if(address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
      openForDeposit = false;
    } 
    else {
      openForWithdraw = true;
    }
  }

  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
  function withdraw() public onlyBeforeStaking {
    require(openForWithdraw, "Contract is not open for withdraw");
    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;
    bool success = payable(msg.sender).send(amount);
    require(success, "transaction failed");
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    return (block.timestamp >= deadline?  0 : deadline - block.timestamp);
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable { 
    stake();
  }
}
