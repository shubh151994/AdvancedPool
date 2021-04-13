
//SPDX-License-Identifier: UNLICENSED
pragma solidity >0.6.0;
import "../libraries/SafeMath.sol";
import "../interfaces/IERC20.sol"; 
import "../interfaces/uniswapRouter.sol";
import "../interfaces/EthToEosBridge.sol";


contract BridgeStorageV1 {
    
    bytes32 constant EOSTOETH_STORAGE_POSITION = keccak256("diamond.standard.ethtoeosbridge.storage");

    using SafeMath for uint256;
    
    struct Message {
        uint256 id;      
        bytes message;
        uint256 block_num;
        bool received;  
    }

    struct InboundMessage {
        bytes message;
        uint256 block_num;
    }

    struct Config{
        uint256 max_mint_allowed; 
        uint256 max_mint_period_amount;
        uint256 max_mint_period;
        uint256 EOS_precision;
        uint256 ethereum_precision;
    }

     struct MessageType{
        uint64 address_registered;
        uint64 address_modified;
        uint64 mint;
        uint64 deposit;
        uint64 lock;
        uint64 max_mint;
        uint64 min_eth;
        uint64 low_eth;
        uint64 eth_received;
        uint64 swap;
        uint64 max_mint_period_amount;
        uint64 max_mint_period;
    }
    
    struct BridgeStorage {
    
        uint256 total_tokens;
        uint256 receipt_flag;
        uint256 available_message_id;
        uint256 last_outgoing_batch_block_num;
        uint256 last_incoming_batch_block_num;
        uint256 required_sigs;
        uint256 required_sigs_secure;
        uint256 min_eth_required;
        uint64 available_batch_id;
        uint64 next_incoming_batch_id;
        uint64 default_gas;
    
        bool tokenpeg_initialized;
        bool locked;
    
        UniswapV2Router02 uniswapRouter;
        EthToEosBridge ethToEosBridge;
  
        Config[] configs;
        MessageType msg_types;
        
        address[] owners;
        address[] tokens;
        address owner ;
    
        mapping (address => bool) isOwner;
        mapping (uint256 => InboundMessage) inbound;                 
        mapping (uint64 => Message) batches;
        mapping (uint256 => uint64) outbound;
        mapping (bytes32 => mapping(address => bool)) hasConfirmed;
        mapping (bytes32 => bool) executedMsg;
        mapping (bytes32 => uint256) numOfConfirmed;  
        mapping (address => uint256) gas_used;
        mapping (uint256 => uint256) total_period_mint;
        mapping (uint256 => uint256) last_mint_time;
    }

    function bridgeStorage() internal pure returns (BridgeStorage storage bs) {
        bytes32 position = EOSTOETH_STORAGE_POSITION;
        assembly {
            bs.slot := position
        }
    }

}