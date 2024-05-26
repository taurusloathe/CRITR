# app.py
from flask import Flask, request, jsonify
from web3 import Web3
import json

app = Flask(__name__)

# Initialize Web3
infura_url = "https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID"
web3 = Web3(Web3.HTTPProvider(infura_url))

# Load contract ABI and address
with open('FactoryContract.json') as f:
    factory_contract_info = json.load(f)
factory_contract_address = "YOUR_FACTORY_CONTRACT_ADDRESS"
factory_contract_abi = factory_contract_info['abi']

factory_contract = web3.eth.contract(address=factory_contract_address, abi=factory_contract_abi)

@app.route('/deploy', methods=['POST'])
def deploy():
    data = request.json
    token_name = data.get('tokenName')
    token_symbol = data.get('tokenSymbol')
    initial_supply = int(data.get('initialSupply'))
    uniswap_router_address = data.get('uniswapRouterAddress')
    wormhole_address = data.get('wormholeAddress')
    solana_chain_id = int(data.get('solanaChainId'))
    uniswapx_router_address = data.get('uniswapxRouterAddress')

    user_account = data.get('userAccount')
    private_key = data.get('privateKey')

    transaction = factory_contract.functions.deployContracts(
        token_name,
        token_symbol,
        initial_supply,
        uniswap_router_address,
        wormhole_address,
        solana_chain_id,
        uniswapx_router_address
    ).buildTransaction({
        'from': user_account,
        'nonce': web3.eth.getTransactionCount(user_account),
        'gas': 3000000,
        'gasPrice': web3.toWei('20', 'gwei')
    })

    signed_txn = web3.eth.account.sign_transaction(transaction, private_key=private_key)
    tx_hash = web3.eth.send_raw_transaction(signed_txn.rawTransaction)
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    return jsonify({'txHash': tx_hash.hex(), 'txReceipt': tx_receipt})

if __name__ == '__main__':
    app.run(debug=True)
