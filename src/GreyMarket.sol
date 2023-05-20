// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "./GreyMarketStorage.sol";
import "./GreyMarketEvent.sol";
import "./GreyMarketData.sol";

/// @dev Error thrown when the signature is invalid.
error InvalidSignature(bytes32 orderId, Sig sig);
/// @dev Error thrown when a set of signatures are invalid.
error InvalidSignatures(bytes32 orderId, Sig[] sig);
/// @dev Error thrown when the order is not found.
error OrderNotFound(bytes32 orderId);
/// @dev Error thrown when payment token is not supported.
error PaymentTokenNotSupported(address paymentToken);
/// @dev Error thrown when order status is invalid
error InvalidOrderStatus(bytes32 orderId, uint8 status);
/// @dev Error thrown when recipient is invalid
error InvalidRecipient(address recipient);
/// @dev Error thrown when order cannot be admin withdrawn yet
error CannotAdminWithdrawYet(bytes32 orderId);

/** 
 * @title gm.co
 * @custom:version 1.1
 * @author projectPXN
 * @custom:coauthor bldr
 * @notice gm.co is a Business-to-Consumer (B2C) and Peer-to-Peer (P2P) marketplace
 *         using blockchain technology for proof of transactions and allow users
 *         to buy and sell real world goods using cryptocurrency.
 */
contract GreyMarket is Ownable, GreyMarketStorage, GreyMarketEvent, EIP712 {
    constructor(address _proofSigner, address _usdc) EIP712("GreyMarket Contract", "1.1.0") {
        require(_usdc != address(0) && _proofSigner != address(0), "invalid token or signer address");

        proofSigner = _proofSigner;
        paymentTokens[_usdc] = true;
    }

    /**
     * @notice Create the order.
     * @dev Create the order with order information.
     * @param id Order id
     * @param seller Address of the seller
     * @param paymentToken Address of the payment token used for the order
     * @param orderType Type of the order
     * @param amount Payment amount
     * @param sig ECDSA signature
     */
    function createOrder(
        bytes32 id, 
        address seller, 
        address paymentToken,
        uint8 orderType, 
        uint256 amount, 
        Sig calldata sig
    ) external payable {
        if(!validateCreateOrder(sig, id, msg.sender, seller, paymentToken, orderType, amount))
            revert InvalidSignature(id, sig);

        if(paymentToken != address(0))
            IERC20(paymentToken).transferFrom(msg.sender, address(this), amount);

        emit OrderCreated(
            id, 
            msg.sender, 
            seller, 
            uint8(paymentToken == address(0) ? 0 : 1), 
            orderType, 
            uint128(block.timestamp), 
            amount
        );
    }

    /**
     * @notice Claim the order fund by seller after order is delivered and confirmed.
     * @dev Claim the order fund with order information.
     * @param id Order id
     * @param buyer Address of the buyer
     * @param seller Address of the seller
     * @param amount Amount of funds to claim
     * @param paymentToken Token used to claim funds
     * @param orderType Type of the order
     * @param sig ECDSA signature
     */
    function claimOrder(
        bytes32 id,
        address buyer,
        address seller,
        uint256 amount,
        uint8 orderType,
        address paymentToken,
        Sig calldata sig
    ) public {
        if(!validateClaimOrder(sig, id, buyer, seller, amount, paymentToken, orderType, 4))
            revert InvalidSignature(id, sig);

        uint256 fee = amount * transactionFee / 100000;
        uint256 escrowFee;

        if(orderType == 1) { 
            escrowFee = amount * defaultEscrowFee / 100000;
            escrowFees[seller][paymentToken] = escrowFees[seller][paymentToken] + escrowFee * 90 / 100;
        }

        adminFees[paymentToken] = adminFees[paymentToken] + fee + escrowFee * 10 / 100;
        if (paymentToken == address(0))
            payable(seller).transfer(amount - fee + escrowFee * 90 / 100);
        else
            IERC20(paymentToken).transfer(seller, amount - fee + escrowFee * 90 / 100);

        emit OrderCompleted(id, buyer, seller, uint128(block.timestamp));
    }
    
    /**
     * @notice Withdraw funds for a buyer after an order is cancelled
     * @dev Withdraw the order fund with order data
     * @param id Order id
     * @param buyer Address of the buyer
     * @param seller Address of the seller
     * @param paymentToken Address of the payment token used for the order
     * @param amount Amount of funds to withdraw
     * @param sig ECDSA signature
     */
    function withdrawOrder(
        bytes32 id, 
        address buyer, 
        address seller, 
        address paymentToken,
        uint256 amount,
        Sig calldata sig
    ) external {
        if(!validateWithdrawOrder(sig, id, buyer, seller, paymentToken, amount, 6))
            revert InvalidSignature(id, sig);

        if (paymentToken == address(0))
            payable(buyer).transfer(amount);
        else
            IERC20(paymentToken).transfer(buyer, amount);

        emit OrderCancelled(id, buyer, seller, uint128(block.timestamp));
    }

    /**
     * @notice Release the disputed fund by buyer or seller as admin indicated.
     * @dev Release the disputed fund by buyer or seller as admin indicated.
     * @param id Order id.
     * @param buyer Address of the buyer
     * @param seller Address of the seller
     * @param winner Address of the winner
     * @param paymentToken Token used to pay
     * @param amount Amount of funds to release
     * @param sigs Array of the v,r,s values of the ECDSA signatures
     */
    function releaseDisputedOrder(
        bytes32 id, 
        address buyer, 
        address seller, 
        address winner, 
        uint256 amount,
        address paymentToken,
        Sig[] calldata sigs
    ) external {
        if(!validateReleaseDisputedOrder(sigs, id, buyer, seller, 8, paymentToken, winner))
            revert InvalidSignatures(id, sigs);

        if (paymentToken == address(0))
            payable(winner).transfer(amount);
        else
            IERC20(paymentToken).transfer(winner, amount);

        emit OrderDisputeHandled(id, buyer, seller, winner, uint128(block.timestamp));
    }

    /**
     * @notice Sets the proof signer address.
     * @dev Admin function to set the proof signer address.
     * @param newProofSigner The new proof signer.
     */
    function setProofSigner(address newProofSigner) external onlyOwner {
        require(newProofSigner != address(0), "invalid proof signer");
        proofSigner = newProofSigner;
        emit NewProofSigner(proofSigner);
    }

    /**
     * @notice Add new market admin.
     * @dev Admin function to add new market admin.
     * @param newAdmins The new admin.
     */
    function setNewAdmins(address[] calldata newAdmins) external onlyOwner {
        require(newAdmins.length > 0, "invalid admins length");
        admins = newAdmins;
        emit NewAdmins(admins);
    }

    /**
     * @notice Add new payment token
     * @dev Admin function to add new payment token
     * @param paymentToken Supported payment token
     * @param add Add or remove admin.
     */
    function addOrRemovePaymentToken(address paymentToken, bool add) external onlyOwner {
        require(paymentToken != address(0), "invalid payment token");
        paymentTokens[paymentToken] = add;
    }

    /**
     * @notice Sets the transaction fee 
     * @dev Admin function to set the transaction fee
     * @param newFee escrow fee recipient.
     */
     function setTransactionFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_TRANSACTION_FEE, "invalid fee range");
        transactionFee = newFee;
        emit NewTransactionFee(newFee);
     }

    /**
     * @notice Sets the escrow fee.
     * @dev Admin function to set the escrow fee.
     * @param newEscrowFee The new escrow fee, scaled by 1e18.
     */
    function setEscrowFee(uint256 newEscrowFee) external onlyOwner {
        require(newEscrowFee <= MAX_ESCROW_FEE, "invalid fee range");
        defaultEscrowFee = newEscrowFee;
        emit NewEscrowFee(newEscrowFee);
    }

    /**
     * @notice Sets the escrow pending period.
     * @dev Admin function to set the escrow pending period.
     * @param newEscrowPendingPeriod The new escrow pending period in timestamp
     */
    function setEscrowPendingPeriod(uint256 newEscrowPendingPeriod) external onlyOwner {
        require(newEscrowPendingPeriod <= MAX_ESCROW_PENDING_PERIOD, "pending period must not exceed maximum period");
        require(newEscrowPendingPeriod >= MIN_ESCROW_PENDING_PERIOD, "pending period must exceed minimum period");
        escrowPendingPeriod = newEscrowPendingPeriod;
        emit NewEscrowPendingPeriod(escrowPendingPeriod);
    }

    /**
     * @notice Sets the escrow lock period.
     * @dev Admin function to set the escrow lock period.
     * @param newEscrowLockPeriod The new escrow lock period in timestamp
     */
    function setEscrowLockPeriod(uint256 newEscrowLockPeriod) external onlyOwner {
        require(newEscrowLockPeriod <= MAX_ESCROW_LOCK_PERIOD, "lock period must not exceed maximum period");
        require(newEscrowLockPeriod >= MIN_ESCROW_LOCK_PERIOD, "lock period must exceed minimum period");
        escrowLockPeriod = newEscrowLockPeriod;
        emit NewEscrowLockPeriod(escrowLockPeriod);
    }

    /**
     * @notice Withdraw the admin fee.
     * @dev Admin function to withdraw the admin fee.
     * @param recipient The address that will receive the fees.
     * @param token The token address to withdraw, NULL for ETH, token address for ERC20.
     * @param amount The amount to withdraw.
     */
    function withdrawAdminFee(address recipient, address token, uint256 amount) external onlyOwner {
        require(recipient != address(0), "invalid recipient address");
        require(adminFees[token] >= amount, "invalid token address or amount");

        if (token == address(0))
            payable(recipient).transfer(amount);
        else
            IERC20(token).transfer(recipient, amount);

        adminFees[token] = adminFees[token] - amount;
        emit WithdrawAdminFee(msg.sender, recipient, token, amount);
    }

    /**
     * @notice Withdraw the unclaimed fund for lock period.
     * @dev Admin function to withdraw the unclaimed fund for lock period.
     * @param id The order id.
     * @param recipient The address that will receive the fees.
     * @param orderStatus Status of the order
     * @param createdAt Timestamp of when the order was created
     * @param amount Amount to withdraw
     * @param paymentToken Address of the payment token
     */
    function withdrawLockedFunds(
        bytes32 id, 
        address recipient, 
        uint8 orderStatus,
        uint256 createdAt,
        uint256 amount,
        address paymentToken
    ) external onlyOwner {
        if(orderStatus == 1)
            revert InvalidOrderStatus(id, orderStatus);

        if(recipient == address(0))
            revert InvalidRecipient(recipient);

        if(createdAt + escrowLockPeriod <= block.timestamp)
            revert CannotAdminWithdrawYet(id);
        
        if (paymentToken == address(0))
            payable(recipient).transfer(amount);
        else
            IERC20(paymentToken).transfer(recipient, amount);

        emit WithdrawLockedFund(msg.sender, id, recipient, amount);
    }

    /**
     * @notice Validates a create order signature
     * @dev Validates the signature of a create order action by verifying the signature
     * @param sig ECDSA signature
     * @param id Order id
     * @param buyer Buyer address
     * @param seller Seller address
     * @param paymentToken Payment token address
     * @param orderType Order type
     * @param amount Order amount
     * @return bool Whether the signature is valid or not
     */
    function validateCreateOrder(
        Sig calldata sig,
        bytes32 id, 
        address buyer, 
        address seller, 
        address paymentToken, 
        uint8 orderType, 
        uint256 amount
    ) internal view returns(bool) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
                CREATE_ORDER_TYPEHASH,
                id,
                buyer,
                seller,
                paymentToken,
                orderType,
                amount
        )));

        return ECDSA.recover(digest, sig.v, sig.r, sig.s) == proofSigner;
    }

    /**
     * @notice Validates a claim order signature
     * @dev Validates the signature of a claim order action by verifying the signature
     * @param sig ECDSA signature
     * @param id Order id
     * @param buyer Buyer address
     * @param seller Seller address
     * @param amount Amount of funds to claim
     * @param paymentToken Payment token address
     * @param orderStatus Order status in integer value
     * @param orderType Order type
     * @return bool Whether the signature is valid or not
     */
    function validateClaimOrder(
        Sig calldata sig,
        bytes32 id, 
        address buyer, 
        address seller, 
        uint256 amount,
        address paymentToken,
        uint8 orderType,
        uint8 orderStatus
    ) internal view returns(bool) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
                CLAIM_ORDER_TYPEHASH,
                id,
                buyer,
                seller,
                amount,
                paymentToken,
                orderType,
                orderStatus
        )));
        
        return ECDSA.recover(digest, sig.v, sig.r, sig.s) == proofSigner;
    }

    /**
     * @notice Validates a withdraw order signature
     * @dev Validates the signature of a withdraw order action by verifying the signature
     * @param sig ECDSA signature
     * @param id Order id
     * @param buyer Buyer address
     * @param seller Seller address
     * @param paymentToken Token used to pay
     * @param orderStatus Order status in integer value
     * @return bool Whether the signature is valid or not
     */
    function validateWithdrawOrder(
        Sig calldata sig,
        bytes32 id, 
        address buyer, 
        address seller, 
        address paymentToken,
        uint256 amount,
        uint8 orderStatus
    ) internal view returns(bool) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
                WITHDRAW_ORDER_TYPEHASH,
                id,
                buyer,
                seller,
                paymentToken,
                amount,
                orderStatus
        )));
        
        return ECDSA.recover(digest, sig.v, sig.r, sig.s) == proofSigner;
    }

    /**
     * @notice Validates a release disputed order signature
     * @dev Validates the signature of a release disputed order action by verifying the signature
     * @param sigs Array of the v,r,s values of the ECDSA signatures
     * @param id Order id
     * @param buyer Buyer address
     * @param seller Seller address
     * @param orderStatus Order status in integer value
     * @param paymentToken Token used to pay
     * @param winner Winner address
     * @return bool Whether the signature is valid or not
     */
    function validateReleaseDisputedOrder(
        Sig[] calldata sigs,
        bytes32 id,
        address buyer,
        address seller,
        uint8 orderStatus,
        address paymentToken,
        address winner
    ) internal view returns(bool) {
        require(sigs.length == REQUIRED_SIGNATURE_COUNT, "invalid signature required count");

        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
                RELEASE_DISPUTED_ORDER_TYPEHASH,
                id,
                buyer,
                seller,
                paymentToken,
                winner,
                orderStatus
        )));
        
        address signerOne = ECDSA.recover(digest, sigs[0].v, sigs[0].r, sigs[0].s);
        address signerTwo = ECDSA.recover(digest, sigs[1].v, sigs[1].r, sigs[1].s);
        require(signerOne != signerTwo, "same signature");

        uint256 validSignatureCount;
        for(uint256 i; i < admins.length; i++) {
            if(signerOne == admins[i] || signerTwo == admins[i]) {
                validSignatureCount++;
            }
        }

        return validSignatureCount == REQUIRED_SIGNATURE_COUNT;
    }
    
    /**
     * @notice View function to get the amount of admin fees by a specific token
     * @dev Retrieves the amount of admin fees by a specific token address, either ETH or ERC20
     * @param token Token address
     * @return uint256 Amount of fees in wei
     */
    function getAdminFeeAmount(address token) public view returns (uint256) {
        return adminFees[token];
    }

    /**
     * @notice Expose typed v4 hash function
     */
    function hash(bytes32 _hash) public view returns (bytes32) {
        return _hashTypedDataV4(_hash);
    }
}
