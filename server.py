import boto3
import os
import requests
import threading
import asyncio
import aiohttp
import csv

input_bucket = "quiz-on-friday-project-3-input-data"
output_bucket = "quiz-on-friday-project-3-output-data"

test_cases = "test_cases/"

rgw_endpoint = "http://192.168.64.6:8080"

access_key = "useraccesskey"
secret_key = "usersecretkey"

openfaas_url = "http://192.168.49.2:31112"
openfaas_endpoint = "http://192.168.49.2:31112/function/custom-cloud.openfaas-fn"
function_name = "custom-cloud.openfaas-fn"


async def get_response(n):
    async with aiohttp.ClientSession() as session:
        responses = await asyncio.gather(*(
            session.post(openfaas_endpoint, data=i)
            for i in n
        ))

        assert all(r.status == 200 for r in responses)

        return [await r.text() for r in responses]

def main(location, filename):
    s3 = boto3.resource('s3',
                        endpoint_url=rgw_endpoint,
                        aws_access_key_id=access_key,
                        aws_secret_access_key=secret_key)

    bucket = s3.Bucket(output_bucket)

    bucket.download_file(Filename=location,
                         Key=filename)

def get_input_files(s3):

    global input_bucket

    invoked = list()
    while True:
        list_obj = s3.list_objects_v2(Bucket=input_bucket)
        if list_obj["KeyCount"] != 0:
            all_objs = list_obj["Contents"]

            for index in range(0, len(all_objs), 10):
                list_of_elems = list()
                for element in all_objs[index:index+10]:
                    list_of_elems.append(element.get("Key"))

                result = asyncio.run(get_response(list_of_elems))
                invoked.extend(list_of_elems)

                if not os.path.exists("csvs"):
                    os.mkdir("csvs")
                
                for elem in list_of_elems:
                    filename = elem.split(".")[0] + ".csv"
                    main(os.path.join("csvs", filename), filename)

                    with open(os.path.join("csvs", filename), "r", newline="") as f:
                        rowreader = csv.reader(f, delimiter=",")
                        for row in rowreader:
                            print(f"{filename}:", row)

            if len(invoked) >= 100:
                break
        else:
            print("No Objects in input bucket")




s3 = boto3.client('s3', endpoint_url=rgw_endpoint, aws_access_key_id=access_key, aws_secret_access_key=secret_key)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      

get_input_files(s3)