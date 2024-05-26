import logging
from cryptography.fernet import Fernet
from flask import Flask, request, jsonify
from flask_cors import CORS
import pymongo
import requests
from web3 import Web3
from requests.exceptions import RequestException

# Logging setup
logging.basicConfig(filename='error_log.txt', level=logging.ERROR)

# MongoDB setup
client = pymongo.MongoClient("mongodb://localhost:27017/")
db = client["YourDatabaseName"]
collection = db["UserCredentials"]

# Generate or load encryption key
def load_key():
    return open("secret.key", "rb").read()

def generate_key():
    key = Fernet.generate_key()
    with open("secret.key", "wb") as key_file:
        key_file.write(key)

# Ensure key exists
try:
    key = load_key()
except FileNotFoundError:
    generate_key()
    key = load_key()

fernet = Fernet(key)

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Secure connection
def establish_secure_connection():
    try:
        response = requests.get("https://example.com", verify=True)
        response.raise_for_status()
        print("Secure connection established.")
    except RequestException as e:
        logging.error(f"Error establishing secure connection: {e}")
        print("Error establishing secure connection.")

# Secure data handling
def secure_data_handling(data):
    encrypted_data = fernet.encrypt(data.encode())
    print("Data encrypted securely.")
    return encrypted_data

# Fetch user credentials
def get_user_credentials(username):
    try:
        user_credential = collection.find_one({"Username": username})
        if user_credential:
            return user_credential
        else:
            print("User credentials not found.")
    except Exception as e:
        logging.error(f"Error fetching user credentials: {e}")
        print("Error fetching user credentials.")

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

    # Validate inputs
    if not all([token_name, token_symbol, uniswap_router_address, wormhole_address, user_account, private_key]):
        return jsonify({"error": "Missing required fields"}), 400

    # Encrypt sensitive data before storing
    encrypted_private_key = secure_data_handling(private_key)

    # Initialize Web3
    web3 = Web3(Web3.HTTPProvider("https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID"))

    # Load contract ABI and address
    with open('FactoryContract.json') as f:
        factory_contract_info = json.load(f)
    factory_contract_address = "YOUR_FACTORY_CONTRACT_ADDRESS"
    factory_contract_abi = factory_contract_info['abi']

    factory_contract = web3.eth.contract(address=factory_contract_address, abi=factory_contract_abi)

    # Build transaction
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

    # Sign the transaction
    signed_txn = web3.eth.account.sign_transaction(transaction, private_key=fernet.decrypt(encrypted_private_key).decode())
    # Send the transaction
    tx_hash = web3.eth.send_raw_transaction(signed_txn.rawTransaction)
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

    return jsonify({'txHash': tx_hash.hex(), 'txReceipt': tx_receipt})

if __name__ == '__main__':
    establish_secure_connection()
    app.run(debug=True, ssl_context='adhoc')  # Run with HTTPS
