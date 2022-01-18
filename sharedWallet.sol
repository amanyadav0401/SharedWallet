// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";



contract SimpleWallet is Ownable{
       
       uint totalBalance;
        event MoneyReceived(address _from, uint _amount);
        event MoneyAllocated(address _from, address _to, uint _amount);

        modifier ownnerOrAllowed(uint _amount){
                       if(isOwner()==true){
                require(address(this).balance >= _amount,"Not enough balance in Smart Contract");
            }
            if(isOwner()!=true){
                require(Funds[msg.sender]._totalBalance >= _amount,"Not enough money allowed to you.");
                require(address(this).balance >= _amount,"Not enough balance in Smart Contract");
            }
            _;
        }

       struct paymentsReceived {
           uint amountreceived;
           uint _timeStamp;
       }

       struct totalReserve {
          uint _totalBalance;
          uint TxNum;
          mapping(uint=>paymentsReceived) _Payment;
       }

       mapping(address => totalReserve) public Funds;

       /* Function that uses two structs, first to store balance with an address as a key,
        other to store the transaction with the transaction number as a key */

       function allocateFunds(address _department, uint _amount) public onlyOwner{
        assert(Funds[msg.sender]._totalBalance - _amount <= Funds[msg.sender]._totalBalance);
        assert(Funds[_department]._totalBalance + _amount >= Funds[_department]._totalBalance);
        Funds[msg.sender]._totalBalance -= _amount;
        Funds[_department]._totalBalance += _amount;
        paymentsReceived memory paymentAllocated = paymentsReceived(_amount,block.timestamp);
        Funds[_department]._Payment[Funds[_department].TxNum] = paymentAllocated;
        Funds[_department].TxNum++;
        emit  MoneyAllocated(msg.sender, _department, _amount);
 }
        /* shows the total balance in the smart contract, that anyone can check whether the owner or the allowed */

       function ShowBalance() public onlyOwner view returns(uint){
               return address(this).balance;
       }
       
       /* A function to withdraw money that checks the withdrawer is an owner or allowed, in case of owner he/she
        is allowed withdraw all money without changing the state of allowance so that the allowed can demand a refill
        in case of a needed withdrawal. */

       function withDrawmoney(address payable _to, uint _amount) public ownnerOrAllowed(_amount){
           require(_amount<=address(this).balance,"Not enough funds in Smart Contract");
           if(isOwner()!=true){
           Funds[msg.sender]._totalBalance -= _amount;
           _to.transfer(_amount);}
           if(isOwner()==true && _amount>=Funds[msg.sender]._totalBalance){
             Funds[msg.sender]._totalBalance = 0;  
            _to.transfer(_amount);
           }
           if(isOwner()==true && _amount < Funds[msg.sender]._totalBalance){
               Funds[msg.sender]._totalBalance -= _amount;
           }
           
       }

        function receiveMoney() public payable {
           /*BalanceReceived(msg.sender,msg.value);*/
           require(isOwner()," - You are not allowed to add funds to smart contract.");
           Funds[msg.sender]._totalBalance += msg.value;
           paymentsReceived memory paymentReceived = paymentsReceived(msg.value,block.timestamp);
           Funds[msg.sender]._Payment[Funds[msg.sender].TxNum] = paymentReceived;
           Funds[msg.sender].TxNum++;
           emit MoneyReceived(msg.sender,msg.value);
       }

}
