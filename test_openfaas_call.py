import requests

def invoke_openfaas_function(endpoint, function_name, body):
    url = f"{endpoint}/function/{function_name}"
    headers = {"Content-Type": "text/plain"}

    response = requests.post(url, data=body, headers=headers)

    if response.status_code == 200:
        print("Function invoked successfully!")
        print("Response:", response.text)
    else:
        print(f"Error invoking function. Status code: {response.status_code}")
        print("Error response:", response.text)

openfaas_endpoint = "http://192.168.49.2:31112"
function_name = "custom-cloud.openfaas-fn"
body="test_99.mp4"

invoke_openfaas_function(openfaas_endpoint, function_name, body)

# 192.168.49.2:31112/function/custom-cloud.openfaas-fn
