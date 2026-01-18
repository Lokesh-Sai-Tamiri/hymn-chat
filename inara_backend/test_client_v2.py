import requests
import time
import json

# Base URL
url = "http://127.0.0.1:8000"
chat_url = f"{url}/api/chat"
sessions_url = f"{url}/api/sessions"
user_sessions_url = f"{url}/api/users"

def test_user_session_flow():
    user_id = "test_user_404"
    print(f"\n--- Testing User Session Flow for {user_id} ---")

    # 1. Create Explicit Session
    print("\n1. Creating Session explicitly...")
    try:
        resp = requests.post(sessions_url, json={"user_id": user_id})
        if resp.status_code == 200:
            session_data = resp.json()
            session_id = session_data['session_id']
            print(f"Created Session: {session_id}")
        else:
            print("Failed to create session:", resp.text)
            return
    except Exception as e:
        print("Error:", e)
        return

    # 2. Add message to this session
    print("\n2. Chatting in this session...")
    payload = {
        'message': 'Hello, I am testing user APIs.',
        'session_id': session_id
    }
    resp = requests.post(chat_url, data=payload)
    print(f"Chat Response: {resp.json().get('response')}")

    # 3. List User Sessions
    print(f"\n3. Listing sessions for {user_id}...")
    resp = requests.get(f"{user_sessions_url}/{user_id}/sessions")
    sessions = resp.json()
    print(f"Found {len(sessions)} sessions.")
    found = any(s['session_id'] == session_id for s in sessions)
    print(f"Current session found in list: {found}")

    # 4. Get specific session details
    print(f"\n4. Fetching history for {session_id}...")
    resp = requests.get(f"{sessions_url}/{session_id}")
    history = resp.json().get('history', [])
    print(f"History length: {len(history)} items (should be >= 2: User + Model)")

if __name__ == "__main__":
    print("Ensure server is running...")
    test_user_session_flow()
