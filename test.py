import requests
import json

# --- Configuration ---
# Your Hugging Face Space base URL
# Ensure this is the direct URL for your Space, not the general Hugging Face Hub page.
BASE_URL = "https://nab3588-allearsapi.hf.space"

# The specific endpoint for classification
CLASSIFY_ENDPOINT = "/classify"

# Full URL for the classify endpoint
CLASSIFY_URL = f"{BASE_URL}{CLASSIFY_ENDPOINT}"

# Data payload for the POST request
# Replace 'Your test prompt here' with a message you want to classify
# Replace 'your_unique_id_here' with a test ID (can be any string)
payload = {
    "prompt": "I am feeling happy today, tell me a joke!",
    "id": "python_test_user_12345"
}

# Headers for the POST request
# Content-Type is essential for sending JSON data
headers = {
    "Content-Type": "application/json"
}

print(f"Attempting to send POST request to: {CLASSIFY_URL}")
print(f"Payload: {json.dumps(payload, indent=2)}")

try:
    # Make the POST request
    response = requests.post(CLASSIFY_URL, headers=headers, data=json.dumps(payload))

    # Print the response status code
    print(f"\nResponse Status Code: {response.status_code}")

    # Print the response body (as JSON if possible, otherwise raw text)
    try:
        response_json = response.json()
        print("Response Body (JSON):")
        print(json.dumps(response_json, indent=2))
    except json.JSONDecodeError:
        print("Response Body (Raw Text):")
        print(response.text)

    # Check for successful response (status code 200)
    if response.status_code == 200:
        print("\nSuccessfully classified message!")
    else:
        print(f"\nError: API call failed with status code {response.status_code}")
        print("Please check the response body for more details.")

except requests.exceptions.RequestException as e:
    print(f"\nAn error occurred during the request: {e}")
    print("This could be a network issue, an incorrect URL, or the server being unreachable.")

