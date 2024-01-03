import csv
import os
import pickle

import boto3
import cv2
import face_recognition
from boto3.dynamodb.conditions import Attr

input_bucket = "quiz-on-friday-project-3-input-data"
output_bucket = "quiz-on-friday-project-3-output-data"
test_cases = "test_cases/"

rgw_endpoint = "http://192.168.64.6:8080"
access_key = "useraccesskey"
secret_key = "usersecretkey"

aws_key = open("/var/openfaas/secrets/openfaas-aws-access-key", "r").read()
aws_secret = open("/var/openfaas/secrets/openfaas-aws-secret-key", "r").read()
dynamodb_region = os.environ["dynamodb_region"]
dynamodb_table = os.environ["dynamodb_table"]


# def search_database_table(attribute_value):
def search_database_table(attribute_value):
    client = boto3.Session(region_name=dynamodb_region).resource(
        "dynamodb", aws_access_key_id=aws_key, aws_secret_access_key=aws_secret
    )
    table = client.Table(dynamodb_table)  # type: ignore

    response = table.scan(FilterExpression=Attr("name").eq(attribute_value))  # type: ignore

    return response["Items"][0]


# Function to read the 'encoding' file
def open_encoding(filename):
    file = open(filename, "rb")
    data = pickle.load(file)
    file.close()
    return data


def handle(req):
    """handle a request to the function
    Args:
        req (str): request body
    """
    s3 = boto3.client('s3', endpoint_url=rgw_endpoint, aws_access_key_id=access_key, aws_secret_access_key=secret_key)
    if not os.path.exists("/tmp"):
        os.mkdir("/tmp")
    
    local_filename = "/tmp/" + req
    s3.download_file(input_bucket, req, local_filename)

    video_file_path = local_filename
    
    encodings_dict = open_encoding("/home/app/function/encoding")

    # Convert the dictionary to separate lists of known_faces and known_names

    known_faces = list(encodings_dict["encoding"])
    known_names = list(encodings_dict["name"])


    test_image_name = req.split(".")[0]
    # Extract frames from the video using ffmpeg
    os.system(
        f"ffmpeg -i {video_file_path} -r 1 /tmp/{test_image_name}-%3d.jpeg"
    )
    # Process each extracted frame
    for i in range(
        1, 100
    ):  # Adjust the range depending on the number of frames extracted
        image_path = f"/tmp/{test_image_name}-{i:03d}.jpeg"
        if os.path.isfile(image_path):
            # Load the image
            unknown_image = face_recognition.load_image_file(image_path)
            face_encodings = face_recognition.face_encodings(unknown_image)[0]
            matches = face_recognition.compare_faces(
                known_faces, face_encodings
            )
            name = "Unknown"

            # If there is a match, use the known face's name
            if True in matches:
                first_match_index = matches.index(True)
                name = known_names[first_match_index]
                result = search_database_table(name)
                output_file_name = req.split(".")[0]
                output = [
                    result["name"],
                    result["major"],
                    result["year"],
                ]

                output_path = output_file_name + ".csv"
                with open("/tmp/" + output_path, mode="w") as file:
                    writer = csv.writer(file)
                    writer.writerow(output)
                # Upload CSV file to S3 bucket
                s3.upload_file(
                    "/tmp/" + output_path, output_bucket, output_path
                )
                os.remove("/tmp/" + output_path)
                break
    
    return {req: output}
