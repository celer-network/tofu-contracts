// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./interfaces/IMarketNG.sol";
import "./lib/MessageReceiverApp.sol";
import "./lib/MessageSenderLib.sol";

contract MarketNGCrosschain is MessageReceiverApp {
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

    constructor(address marketNG_) {
        marketNG = marketNG_;
    }

    /**
     * @notice initiates a cross-chain call the the _chainId chain
     * @param _dstChainId the destination chain to purchase NFT on
     * @param _dstCrossChainEndpoint the CrossChainEndpoint contract on the destination chain
     * @param _receiver the address on destination chain to receive target NFT
     * @param _srcToken The address of the transfer token.
     * @param _amount The amount of the transfer
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * @param _order input order, accquired from the Tofu backend server
     */
    function purchase(
        uint64 _dstChainId,
        address _dstCrossChainEndpoint,
        address _receiver,
        address _srcToken,
        uint32 _amount,
        uint32 _maxSlippage,
        Order memory _order
    ) external payable {
        nonce += 1;
        require(_amount >= _order.detail.price, "invalid amount");
        IERC20(_srcToken).safeTransferFrom(msg.sender, address(this), _amount);
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
     * @param _amount The amount of the transfer
     * @param _message packed PurchaseRequest
     */
    function executeMessageWithTransfer(
        address, // _sender
        address _dstToken,
        uint256 _amount,
        uint64, //_srcChainId
        bytes memory _message,
        address // executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        PurchaseRequest memory request = abi.decode((_message), (PurchaseRequest));
        require(_dstToken == address(request.order.detail.currency), "invalid token type");
        IERC20(request.order.detail.currency).approve(marketNG, request.order.detail.price);
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
        if (_amount > request.order.detail.price) {
            IERC20(request.order.detail.currency).transferFrom(
                address(this),
                request.receiver,
                _amount - request.order.detail.price
            );
        }
        return ExecutionStatus.Success;
    }

    /**
     * @notice called only if handleMessageWithTransfer was reverted (etc, NFT sold out)
     * @param _token the token used on destination chain
     * @param _amount The amount of the transfer
     * @param _message packed PurchaseRequest
     */
    function executeMessageWithTransferFallback(
        address, //_sender
        address _token,
        uint256 _amount,
        uint64, // _srcChainId
        bytes memory _message,
        address // executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        PurchaseRequest memory request = abi.decode((_message), (PurchaseRequest));
        require(_token == address(request.order.detail.currency), "invalid token type");
        IERC20(request.order.detail.currency).transferFrom(address(this), request.receiver, _amount);
        return ExecutionStatus.Success;
    }

    /**
     * @notice called on source chain for handling of bridge failures (bad liquidity, bad slippage, etc...)
     * @param _token the token used on source chain
     * @param _amount The amount of the transfer
     * @param _message packed PurchaseRequest
     */
    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message,
        address // executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        PurchaseRequest memory request = abi.decode((_message), (PurchaseRequest));
        IERC20(_token).safeTransfer(request.sender, _amount);
        return ExecutionStatus.Success;
    }
}
