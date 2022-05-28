//SPDX-License-Identifier:UNLICENSED

pragma solidity ^0.8.0;

contract multipartyWallet {
    address[] public owners;
    address Administer;
    uint numberOfProposals;
    uint public approvalPercent=60;
    //to store the 
    struct transactionProposal{
        address initiator;
        address to;
        uint amount;
        bool proposalOver;
    }
    struct proposalVote {
        uint yes;
        uint no; 
        uint totalVotes;
    }

    struct vote{
        uint weight;
        bool voted;
    }
    mapping (uint=>transactionProposal) proposals;
    mapping (address=>mapping(address=>bool)) voteDelegated;
    mapping (uint=>mapping(address=>vote)) votingRight;
    mapping (address=>bool) isOwner;
    mapping (uint=>proposalVote)registerVote;

    modifier administerOnly(){
       require(msg.sender==Administer,"This is Administer's call.");
        _;
    }

    constructor(address[] memory _owners){
        
        Administer=msg.sender;
        owners = _owners;    
        uint totalOwners = _owners.length;
        for(uint i=0; i<totalOwners; i++){
            isOwner[_owners[i]]=true;
        }
    }
    
    function removeOwner(address _owner) public administerOnly{
         isOwner[_owner] = false;
    }

    function delegateVoteForProposal(uint _proposalNo, address _to) public {
        uint voteweigh = votingRight[_proposalNo][msg.sender].weight;
        votingRight[_proposalNo][msg.sender].weight=0;
        votingRight[_proposalNo][_to].weight+=voteweigh;
    }

    function initiateProposal(address _to, uint _amount) public{
        require(isOwner[msg.sender]!=false,"You are not one of the owners.");
         numberOfProposals++;
         proposals[numberOfProposals].initiator= msg.sender;
         proposals[numberOfProposals].to = _to;
         proposals[numberOfProposals].amount = _amount;
         uint totalOwners=owners.length;
        for(uint i=0;i<totalOwners;i++){
           votingRight[numberOfProposals][owners[i]].weight=1;
        }    
    }
    
    function approveProposal(uint proposalNo, bool _vote) public {
        require(proposals[proposalNo].proposalOver!=true,"This proposal is already over.");
        require(isOwner[msg.sender]!=false,"You are not one of the owners");
        require(votingRight[proposalNo][msg.sender].voted!=true,"You have already voted");
        require(votingRight[proposalNo][msg.sender].weight!=0,"Your voting right is dilluted");
         if(_vote==true){ registerVote[proposalNo].yes++;}
         if(_vote==false){ registerVote[proposalNo].no++;}
         registerVote[proposalNo].totalVotes++;
         votingRight[proposalNo][msg.sender].weight--;
         if(votingRight[proposalNo][msg.sender].weight==0){votingRight[proposalNo][msg.sender].voted=true;}
    }

    function executeProposal(uint _proposalNo) public {
        require(proposals[_proposalNo].initiator==msg.sender,"You are not initiator of the proposal.");
        require(registerVote[_proposalNo].totalVotes==owners.length,"Not every owner has approved the proposal");
        uint totalVoted = registerVote[_proposalNo].totalVotes*10000;
        uint yes = registerVote[_proposalNo].yes*10000;
        require(yes>=(totalVoted*approvalPercent)/100,"Your proposal doesn't have enough approvals.");
        proposals[_proposalNo].to.call{value:proposals[_proposalNo].amount};
    }

    function setApprovalPercent(uint _approvalPercent) public administerOnly{
        approvalPercent=_approvalPercent;
    }

    fallback() external payable {}
}
