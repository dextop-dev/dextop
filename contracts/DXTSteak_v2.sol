//                                      $#&WELCOME&#$
//                               https://youtu.be/Ym9JY1t_CYk                          
//                              #%%%%%%%%%%%%%%%%%%%%%%%%%%%%&                              
//                         #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&                         
//                     *######%%%%%                        %%%%%%%%%%%%                     
//                  (########%    %#%%        &@         %%%    %%%%%%%%%&                  
//                ########   ######.       /&@@@@@(        %%%%%#   %%%%%%%%                
//              #######   ######         &&&@@&&&&            %##%%%   %%%%%%%.             
//            #######  .#####,        *&&&&&&&&     %%%#         #####/  %%%%%%%            
//          #######  .((###         &&&&&&&&&     #%%%%%%%         #####%  %%%%%%%          
//         (#####*  (((((        ,%&&&&&&&     (    ##%#%%%%/        .####   %%#%##         
//        ######   (((,        %%%%&&%&&    %%%%%%    ,##%%%%%%         ###(  ######        
//       (###(#   ((.        %%%%%%%%     ##%##%#        ###%%%%%,        ##   ######       
//      #(((((            %%%%%%%%&    ########    ####    ,###%%%%%            ######      
//      (((((#          %%%%%%%%     #######.     #######.    ####%%%%,          #####(     
//     #(((((        ######%#%    ########          ########    /####%%%%        ######     
//     ((((((      ########     #######*    &&DXT&    .#######.    ######%%      ######     
//     ((((((   (########    ########      &DEXTOP&      ########    (#######%   ######     
//     ((((((      ########    #####(((     &ETH&&     ########    (#######/     ######     
//     #(((((        ((((#(((     #(((((((          ,#######,    ((((((##        ######     
//      ((((((          ((((((((    ((((((((      (((#####    /((((((((         /#####,     
//      ((((((            ((((((((     ((((*   ,((((((#/    //((((((            ######      
//       ((((((   **        .((((((((        ((((((((    *//////(/        //   ######       
//        (((((/   ***,        (/((((((     ((((((*    ////////         **/   ((((##        
//         ((///((  ,**,*        .////(//(    /(    ,////////        *****  *((((((         
//          ///////   ,,,,,         ////////      *******/         *****.  (((((((          
//            ///////   ,,,,,,        ,////    .********        ,*****   ///((((            
//              ///////*  .,,,,,.            ********         ,*****  .///////.             
//                ////////    ,,,,,,        *******        ,,,,,    ////////                
//                  *////////*    .,,,        **         ,,.    ****//////                  
//                     ,//////*****                        ************                     
//                       ******************************************                         
//   		                   ,********-=dextop.io=-********,                       
//                                      
//                                                                                          
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title DXTSteak - A staking contract for DXT
contract DXTSteak is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct StakerInfo {
        bool isActive;
        uint256 lockedAmount;
        uint256 lastStakeTime;
        uint256 lastClaimTime;
        uint256 totalDxtClaimed;
    }

    IERC20 public DXT;
    mapping(address => StakerInfo) public stakersInfo;
    address[] private allStakers;
    uint256 public totalActiveStakers;
    uint256 public totalLockedBalance;
    uint256 public totalDxtClaimed;
    uint256 public constant CLAIM_INTERVAL = 7 days;
    uint256 public constant UNLOCK_INTERVAL = 7 days;

    event DxtLocked(address indexed user, uint256 amount);
    event DxtUnlocked(address indexed user, uint256 amount);
    event DxtClaimed(address indexed user, uint256 amount);

    constructor() Ownable(msg.sender) {}

    function setDXTAddress(address _token) external onlyOwner {
        require(address(DXT) == address(0), "DXT address already set");
        DXT = IERC20(_token);
    }

    /// @notice Allows a user to lock DXT tokens into the contract for staking
    /// @param amount The amount of DXT tokens to stake
    function lockTokens(uint256 amount) external nonReentrant {
        require(amount >= 1e18, "Minimum stake is 1 DXT");
        StakerInfo storage staker = stakersInfo[msg.sender];
        require(
            staker.lockedAmount == 0,
            "User can only have one active stake"
        );

        if (!staker.isActive) {
            if (staker.lockedAmount == 0) {
                allStakers.push(msg.sender);
            }
            staker.isActive = true;
            totalActiveStakers += 1;
        }

        staker.lockedAmount += amount;
        staker.lastStakeTime = block.timestamp;
        staker.lastClaimTime = block.timestamp;
        totalLockedBalance += amount;

        DXT.safeTransferFrom(msg.sender, address(this), amount);
        emit DxtLocked(msg.sender, amount);
    }

    /// @notice Allows a user to unlock their staked DXT tokens
    /// @param amount The amount of DXT tokens to unlock
    function unlockTokens(uint256 amount) external nonReentrant {
        require(amount >= 1e18, "Minimum unlock is 1 DXT");
        StakerInfo storage staker = stakersInfo[msg.sender];
        require(staker.isActive, "No active stake found");
        require(staker.lockedAmount >= amount, "Insufficient stake balance");
        require(
            block.timestamp >= staker.lastStakeTime + UNLOCK_INTERVAL,
            "Unlocking too soon"
        );

        staker.lockedAmount -= amount;
        totalLockedBalance -= amount;

        if (staker.lockedAmount == 0) {
            staker.isActive = false;
            totalActiveStakers -= 1;
            removeFromAllStakers(msg.sender);
        }

        DXT.safeTransfer(msg.sender, amount);
        emit DxtUnlocked(msg.sender, amount);
    }

    /// @notice Allows a user to add more DXT tokens to their existing stake
    /// @param additionalAmount The additional amount of DXT tokens to stake
    function addToStake(uint256 additionalAmount) external nonReentrant {
        require(additionalAmount >= 1e18, "Minimum addition is 1 DXT");
        StakerInfo storage staker = stakersInfo[msg.sender];
        require(staker.isActive, "No active stake found");

        staker.lockedAmount += additionalAmount;
        staker.lastStakeTime = block.timestamp;
        totalLockedBalance += additionalAmount;

        DXT.safeTransferFrom(msg.sender, address(this), additionalAmount);
        emit DxtLocked(msg.sender, additionalAmount);
    }

    /// @notice Allows a user to claim their rewards based on their pool share
    function claimDxt() external nonReentrant {
        StakerInfo storage staker = stakersInfo[msg.sender];
        require(staker.isActive, "No active stake found");
        require(
            block.timestamp >= staker.lastClaimTime + CLAIM_INTERVAL,
            "Claiming too soon"
        );

        uint256 claimAmount = calculateClaimableAmount(msg.sender);
        require(claimAmount >= 1e18, "Claim amount must be at least 1 DXT");

        staker.totalDxtClaimed += claimAmount;
        totalDxtClaimed += claimAmount;
        staker.lastClaimTime = block.timestamp;

        DXT.safeTransfer(msg.sender, claimAmount);
        emit DxtClaimed(msg.sender, claimAmount);
    }

    /// @notice Calculates the claimable amount of rewards for a given staker
    /// @param stakerAddress The address of the staker
    /// @return The amount of rewards the staker can claim
    function calculateClaimableAmount(address stakerAddress)
        public
        view
        returns (uint256)
    {
        StakerInfo storage staker = stakersInfo[stakerAddress];
        if (staker.lockedAmount == 0 || totalLockedBalance == 0) {
            return 0;
        }

        uint256 totalDxtInContract = DXT.balanceOf(address(this));
        if (totalDxtInContract <= totalLockedBalance) {
            return 0;
        }

        uint256 rewardsPool = totalDxtInContract - totalLockedBalance;
        uint256 stakerShare = (rewardsPool * staker.lockedAmount) /
            totalLockedBalance;

        return stakerShare;
    }

    /// @notice Retrieves a batch of staker addresses
    /// @param startIndex Start the batch from = 0
    /// @return stakersBatch An array of staker addresses
    /// @return nextIndex The index for the next batch
    function getStakersBatch(uint256 startIndex)
        external
        view
        returns (address[] memory stakersBatch, uint256 nextIndex)
    {
        uint256 maxBatchSize = 9;
        stakersBatch = new address[](maxBatchSize);
        uint256 count = 0;
        uint256 currentIndex = startIndex;

        while (count < maxBatchSize && currentIndex < allStakers.length) {
            address stakerAddress = allStakers[currentIndex];
            if (stakersInfo[stakerAddress].isActive) {
                stakersBatch[count] = stakerAddress;
                count++;
            }
            currentIndex++;
        }

        // Adjust the size of the stakersBatch array to match the actual number of active stakers found
        if (count < maxBatchSize) {
            assembly {
                mstore(stakersBatch, count) // Resize the dynamic array to fit the count
            }
        }

        nextIndex = currentIndex < allStakers.length ? currentIndex : 0;

        return (stakersBatch, nextIndex);
    }

    function removeFromAllStakers(address stakerAddress) private {
        for (uint256 i = 0; i < allStakers.length; i++) {
            if (allStakers[i] == stakerAddress) {
                allStakers[i] = allStakers[allStakers.length - 1];
                allStakers.pop();
                break;
            }
        }
    }
}

//⠄⣿⣷⣯⣭⡷⠄⠄⢀⣀⠩⠍⢉⣛⣛⠫⢏⣈⣭⣥⣶⣶⣦⣭⣛⠄⠄⠄⠄⠄
//⢀⣿⣿⣿⡿⠃⢀⣴⣿⣿⣿⣎⢩⠌⣡⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠄⠄⠄
//⢸⡿⢟⣽⠎⣰⣿⣿⣿⣿⣿⣿⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠄⠄
//⣰⠯⣾⢅⣼⣿⣿⣿⣿⣿⣿⡇⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠄
//⢰⣄⡉⣼⣿⣿⣿⣿⣿⣿⣿⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠄
//⢯⣌⢹⣿⣿⣿⣿⣿⣿⣿⣿⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠄
//⢸⣇⣽⣿⣿⣿⣿⣿⣿⣿⣿⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠄
//⢸⣟⣧⡻⣿⣿⣿⣿⣿⣿⣿⣧⡻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠄
//⠈⢹⡧⣿⣸⠿⢿⣿⣿⣿⣿⡿⠗⣈⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠄
//⠄⠘⢷⡳⣾⣷⣶⣶⣶⣶⣶⣾⣿⣿⢀⣶⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⠇
// E-Mail: team@dextop.dev
// Session ID: 05dc3f32f9cfd944c2ed3081563ee2bee5c51fb90daf232c6a39c2207311c19945