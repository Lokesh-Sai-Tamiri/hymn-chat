import requests
import time

# Base URL
url = "http://127.0.0.1:8000/api/chat"

def test_chat_session():
    print("--- Testing Chat Session & Persona ---")
    
    # 1. Start session, introduce context
    print("\n1. Sends: 'Hello, my name is Lokesh.'")
    payload1 = {'message': 'Hello, my name is Lokesh.'}
    try:
        response1 = requests.post(url, data=payload1)
        if response1.status_code == 200:
            data1 = response1.json()
            session_id = data1.get('session_id')
            print(f"Response: {data1.get('response')}")
            print(f"Session ID received: {session_id}")
            
            if not session_id:
                print("Error: No Session ID returned!")
                return

            # 2. Follow up using session_id
            print("\n2. Sends: 'What is my name?' (expecting Lokesh)")
            payload2 = {
                'message': 'What is my name?',
                'session_id': session_id
            }
            response2 = requests.post(url, data=payload2)
            if response2.status_code == 200:
                print(f"Response: {response2.json().get('response')}")
            else:
                print("Error:", response2.status_code, response2.text)

            # 3. Test Persona
            print("\n3. Sends: 'Who are you?' (expecting Inara)")
            payload3 = {
                'message': 'Who are you?',
                'session_id': session_id
            }
            response3 = requests.post(url, data=payload3)
            if response3.status_code == 200:
                print(f"Response: {response3.json().get('response')}")
            else:
                print("Error:", response3.status_code, response3.text)

        else:
            print("Error:", response1.status_code, response1.text)
    except Exception as e:
        print("Failed to connect:", e)

if __name__ == "__main__":
    print("Ensure the server is running on port 8000")
    test_chat_session()
