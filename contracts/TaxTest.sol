// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "hardhat/console.sol";

contract TaxCalculator {
    function Divide(uint256 amount) public pure {
        uint256 recieverBalance = 0;
        console.log("Receiver Balance:", recieverBalance);

        uint256 _balance = 631160270356169730649672;
        console.log("Seller Balance:", _balance);

        uint256 _stakeBalance = 0;

        uint256 receiveAmount = amount;
        console.log("Receive Amount:", receiveAmount);

        uint256 taxAmount = 0;
        uint256 sellTax = 3;
        uint256 sellTaxAmount = (amount * sellTax) / 100;

        uint256 burnAmount = (sellTaxAmount * 1) / 3; // 1/3 of sellTax for burn
        uint256 DXTSteakAmount = sellTaxAmount - burnAmount; // Remaining for DXTSteak

        taxAmount += sellTaxAmount;
        console.log("Tax Amount:", taxAmount);
        console.log("Burn Amount:", burnAmount);

        _stakeBalance += DXTSteakAmount;
        console.log("Stake Amount:", DXTSteakAmount);

        receiveAmount -= taxAmount;
        console.log("Receive Amount after Tax:", receiveAmount);

        recieverBalance += receiveAmount;

        _balance -= amount;
        console.log("Seller Balance:", _balance);
        console.log("Receiver Balance:", recieverBalance);
    }
}