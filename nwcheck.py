from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

WEALTHENGINE_API_KEY = "YOUR_WEALTHENGINE_API_KEY"

def fetch_net_worth(email):
    url = f"https://api.wealthengine.com/v1/profile/find_one?email={email}&profile=wealth"
    headers = {
        "Authorization": f"Bearer {WEALTHENGINE_API_KEY}",
        "Content-Type": "application/json"
    }
    response = requests.get(url, headers=headers)
    
    if response.status_code == 200:
        data = response.json()
        net_worth = data.get("netWorth", 0)
        return net_worth
    else:
        return None

@app.route('/check-net-worth', methods=['POST'])
def check_net_worth():
    email = request.json.get('email')
    if not email:
        return jsonify({"error": "Email is required"}), 400

    net_worth = fetch_net_worth(email)
    
    if net_worth is None:
        return jsonify({"error": "Unable to retrieve net worth"}), 500

    if net_worth > 100000:
        return jsonify({"access": "denied", "net_worth": net_worth}), 403
    else:
        return jsonify({"access": "granted", "net_worth": net_worth}), 200

if __name__ == '__main__':
    app.run(debug=True)
