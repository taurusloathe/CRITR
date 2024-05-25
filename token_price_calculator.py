def calculate_exponential_curve_price_after_floor(initial_price, price_floor_limit, total_tokens_sold, tokens_to_buy):
    total_price = 0

    for i in range(tokens_to_buy):
        current_token_index = total_tokens_sold + i
        if current_token_index < price_floor_limit:
            total_price += initial_price
        else:
            # Calculate the exponential price for tokens beyond the floor limit
            exponential_price = initial_price * (2 ** ((current_token_index - price_floor_limit) / 500))
            total_price += exponential_price

    return total_price

def token_price_calculator():
    initial_price = 10000000000000  # 0.00001 ETH in wei
    price_floor_limit = 5999  # First 5,999 tokens sold at initial price

    total_tokens_sold = int(input("Enter the total number of tokens already sold: "))
    tokens_to_buy = int(input("Enter the number of tokens you want to buy: "))

    total_cost = calculate_exponential_curve_price_after_floor(initial_price, price_floor_limit, total_tokens_sold, tokens_to_buy)
    total_cost_in_eth = total_cost / 1e18  # Convert wei to ETH

    print(f"The total price for {tokens_to_buy} tokens is: {total_cost_in_eth} ETH")

# Run the calculator
if __name__ == "__main__":
    token_price_calculator()
