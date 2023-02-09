// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./interfaces/IMarketNG.sol";
import "./lib/MessageReceiverApp.sol";
import "./lib/MessageSenderLib.sol";

contract CrossChainEndpoint is MessageReceiverApp {
    using SafeERC20 for IERC20;

    uint8 public constant TOKEN_MINT = 0; // mint token (do anything)
    uint8 public constant TOKEN_721 = 1; // 721 token
    uint8 public constant TOKEN_1155 = 2; // 1155 token

    address public marketNG;

    uint64 nonce;

    struct Order {
        IMarketNG.Intention intent;
        IMarketNG.Detail detail;
        bytes sigIntent;
        bytes sigDetail;
    }

    struct PurchaseRequest {
        address receiver;
        address sender;
        Order order;
    }

    event MarketNGUpdated(address oldMarketNG, address newMarketNG);

    event PurchaseCompleted(uint256 id); // Detail.id
    event Refunded(uint64 chainId, uint256 id, address token, uint256 amount);

    constructor(address _messageBus, address _marketNG) {
        messageBus = _messageBus;
        marketNG = _marketNG;
    }

    /**
     * @notice initiates a cross-chain call the the _chainId chain
     * @param _dstChainId the destination chain to purchase NFT on
     * @param _dstCrossChainEndpoint the CrossChainEndpoint contract on the destination chain
     * @param _receiver the address on destination chain to receive target NFT
     * @param _srcToken The address of the transfer token.
     * @param amount The amount of the transfer
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * @param _order input order, accquired from the Tofu backend server
     */
    function purchase(
        uint64 _dstChainId,
        address _dstCrossChainEndpoint,
        address _receiver,
        address _srcToken,
        uint256 amount,
        uint32 _maxSlippage,
        Order memory _order
    ) external payable {
        nonce += 1;
        require(amount >= _order.detail.price, "invalid amount");
        IERC20(_srcToken).safeTransferFrom(msg.sender, address(this), amount);
        bytes memory message = abi.encode(PurchaseRequest(_receiver, msg.sender, _order));
        MessageSenderLib.sendMessageWithTransfer(
            _dstCrossChainEndpoint,
            _srcToken,
            _order.detail.price,
            _dstChainId,
            nonce,
            _maxSlippage,
            message,
            MsgDataTypes.BridgeSendType.Liquidity,
            messageBus,
            msg.value
        );
    }

    /**
     * @notice called by executor on the dst chain to execute the NFT purchase
     * @param _dstToken the token used on destination chain
     * @param amount The amount of the transfer
     * @param message packed PurchaseRequest
     */
    function executeMessageWithTransfer(
        address, // _sender
        address _dstToken,
        uint256 amount,
        uint64, //_srcChainId
        bytes memory message,
        address // executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        PurchaseRequest memory request = abi.decode((message), (PurchaseRequest));
        require(_dstToken == address(request.order.detail.currency), "invalid token type");
        IERC20(request.order.detail.currency).safeApprove(marketNG, request.order.detail.price);
        IMarketNG(marketNG).run(
            request.order.intent,
            request.order.detail,
            request.order.sigIntent,
            request.order.sigDetail
        );
        // transfer NFT to receiver
        for (uint256 i = 0; i < request.order.intent.bundle.length; i++) {
            IMarketNG.TokenPair memory p = request.order.intent.bundle[i];
            if (p.kind == TOKEN_721) {
                IERC721(p.token).safeTransferFrom(address(this), request.receiver, p.tokenId);
            } else if (p.kind == TOKEN_1155) {
                IERC1155(p.token).safeTransferFrom(address(this), request.receiver, p.tokenId, p.amount, "");
            } else {
                revert("unsupported token");
            }
        }
        // refund extra token
        if (amount > request.order.detail.price) {
            IERC20(request.order.detail.currency).safeTransferFrom(
                address(this),
                request.receiver,
                amount - request.order.detail.price
            );
        }
        emit PurchaseCompleted(request.order.detail.id);
        return ExecutionStatus.Success;
    }

    function refundAndDone(address token, address _receiver, uint256 amount) private returns (ExecutionStatus) {
        IERC20(token).safeTransfer(_receiver, amount);
        return ExecutionStatus.Success;
    }

    /**
     * @notice called only if handleMessageWithTransfer was reverted (etc, NFT sold out)
     * @param token the token used on destination chain
     * @param amount The amount of the transfer
     * @param message packed PurchaseRequest
     */
    function executeMessageWithTransferFallback(
        address, //_sender
        address token,
        uint256 amount,
        uint64, // _srcChainId
        bytes memory message,
        address // executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        PurchaseRequest memory request = abi.decode((message), (PurchaseRequest));
        IERC20(token).safeTransfer(request.receiver, amount);
        emit Refunded(uint64(block.chainid), request.order.detail.id, token, amount);
        return ExecutionStatus.Success;
    }

    /**
     * @notice called on source chain for handling of bridge failures (bad liquidity, bad slippage, etc...)
     * @param token the token used on source chain
     * @param amount The amount of the transfer
     * @param message packed PurchaseRequest
     */
    function executeMessageWithTransferRefund(
        address token,
        uint256 amount,
        bytes calldata message,
        address // executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        PurchaseRequest memory request = abi.decode((message), (PurchaseRequest));
        IERC20(token).safeTransfer(request.sender, amount);
        emit Refunded(uint64(block.chainid), request.order.detail.id, token, amount);
        return ExecutionStatus.Success;
    }

    function setMarketNG(address _marketNG) public onlyOwner {
        emit MarketNGUpdated(marketNG, _marketNG);
        marketNG = _marketNG;
    }

    function onERC721Received(address, address, uint256, bytes memory) external pure returns (bytes4) {
        // only needed this for receiving NFTs.
        return 0x150b7a02;
    }
}
