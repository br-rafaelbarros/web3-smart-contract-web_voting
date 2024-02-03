// SPDX-License-Identifier: MIT
// Autoriza uso do código inclusive para uso comercial, e exime de qualquer responsabilidade

pragma solidity ^0.8.22;

import "@openzeppelin/contracts/utils/Strings.sol";

struct Candidate {
    uint codeNumber;
    string name;
}

struct Vote {
    uint candidateNumber;
    string votingName;
    uint date;
}

struct SummaryVote {
    uint candidateNumber;
    string candidateName;
    uint totalVotes;
}

struct Voting {
    string name;
    uint limitDate;
    uint[] codeCandidates;
}

contract WebVote {
    
    address owner;
    uint public currentVotingIndex = 0;
    Voting[] public votings;
    Vote[] public votes;
    Candidate[] public candidates;
    constructor(){
        owner = msg.sender;
    }

    function changeOwnerVoting(address walletAddress) public {
        owner = walletAddress;
    }

    function getOwnerVoting() public view returns (address) {
        return owner;
    }

    function addCandidate(string memory name, string memory votingName) public {
        require(msg.sender == owner, "You aren't owner");
        require(loadVotingByName(votingName), "Voting not found!");
       require(cadidateAlreadyIngressed(name), "Already ingressed!");

        uint candidateCode = candidates.length + 1;
        uint candidateNumber = getCadidateNumberByName(name);
        if (candidateNumber == 0){
            Candidate memory newCandidate ;
            newCandidate.name = name;
            newCandidate.codeNumber = candidateCode;
            candidates.push(newCandidate);
        } else {
            candidateCode = candidateNumber;
        }
        votings[currentVotingIndex].codeCandidates.push(candidateCode);

    }

    function loadVotingByName(string memory name) private returns (bool votingFound){
        for (uint x = 0; x < votings.length; x++) { 
            if(stringCompare(votings[x].name, name)) {
                currentVotingIndex = x;
                votingFound = true;
                continue ;
            }
        }
        return votingFound;
    }

    function cadidateAlreadyIngressed(string memory candidateName) private view returns (bool votingFound){
        uint candidateCode = 0; 
        for (uint x = 0; x < candidates.length; x++) { 
            Candidate memory candidate = candidates[x];
            if(stringCompare(candidate.name, candidateName)){
                candidateCode = candidate.codeNumber;
                continue;
            }
        }
        if(candidateCode == 0){
            return false;
        }
        bool isIngressed = false;
        for (uint y = 0; y < votings[currentVotingIndex].codeCandidates.length; y++) { 
            if(candidateCode == votings[currentVotingIndex].codeCandidates[y]) {
                isIngressed = true;
                continue ;
            }
        }   
        return isIngressed;
    }

    function getCadidateNumberByName(string memory name) private view returns (uint candidate){
        for (uint x = 0; x < candidates.length; x++) { 
            if(stringCompare(candidates[x].name, name)){
                return candidates[x].codeNumber;
            }
        }
        return 0;
    }

    function getCadidateByCode(uint code) public view returns (Candidate memory candidate){
        for (uint x = 0; x < candidates.length; x++) { 
            if(candidates[x].codeNumber == code){
                return candidates[x];
            }
        }
    }

    function getVotings() public view returns (Voting[] memory votingsList){
        return votings;
    }

    function getCandidates() public view returns (Candidate[] memory candidatesList){
        return candidates;
    }

    function getCandidatesByVoting(string memory votingName) public returns (Candidate[] memory candidatesList){
        require(loadVotingByName(votingName), "Voting not found");
        Voting memory voting = votings[currentVotingIndex];
        Candidate[] memory candidatesFlow;
        for (uint x = 0; x < votings[currentVotingIndex].codeCandidates.length; x++){
            Candidate memory candidateItem = getCadidateByCode(voting.codeCandidates[x]);
            candidatesFlow[x] = candidateItem;
        }
        return candidates;
    }

    function stringCompare(string memory str1, string memory str2) private pure returns (bool) {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }

    function createVoting(string memory votingName, uint timeVote) public {
        require(msg.sender == owner, "Invalid sender");
        require(!loadVotingByName( votingName), "Voting already exist!");
        Voting memory newVoting;
        newVoting.name = votingName;
        newVoting.limitDate = timeVote + block.timestamp;
        votings.push(newVoting);
    }

    function addVote(uint candidateNumber) public {
        require(votings[currentVotingIndex].limitDate > block.timestamp, "No open voting");
        Vote memory newVote;
        newVote.candidateNumber = candidateNumber;
        newVote.votingName = votings[currentVotingIndex].name;
        newVote.date = block.timestamp;
        votes.push(newVote);
    }

    function getSummaryVotesByVoting(string memory votingName) public returns (SummaryVote[] memory votesList){
   
        require(loadVotingByName(votingName), "Voting not found");
        SummaryVote[] memory votesFromVoting;

        for (uint votesIndex = 0; votesIndex < votes.length; votesIndex++){ // loop in all votes
            
            if (stringCompare(votes[votesIndex].votingName, votings[currentVotingIndex].name)){ // entry only check Votes
            
                uint indexCandidate = 0; // initial value

                Candidate[] memory candidatesByVoting = getCandidatesByVoting(votingName);

                for (uint candidateVotingIndex = 0; candidateVotingIndex < candidatesByVoting.length; candidateVotingIndex++){// loop in candidates
                    if(candidatesByVoting[candidateVotingIndex].codeNumber == votes[votesIndex].candidateNumber){ // entry only match candidate
                        indexCandidate = candidateVotingIndex ++; // set index position candidate in array
                    }
                }

                if(indexCandidate == 0){ // entry only candidate not found then put new in array to return
                    Candidate memory candidate = getCadidateByCode(votes[indexCandidate --].candidateNumber);
                    SummaryVote memory voteItem;
                    voteItem.candidateNumber = candidate.codeNumber;
                    voteItem.candidateName = candidate.name;
                    voteItem.totalVotes = 1;
                    votesFromVoting[votesFromVoting.length + 1] = voteItem; // push in last position new vote
                } else { // existing candidate add new vote
                    votesFromVoting[indexCandidate--].totalVotes = votesFromVoting[indexCandidate--].totalVotes + 1;
                }

            }
        }
        return votesFromVoting;
    }
}