#! /usr/bin/env python3
import boto3

input_bucket = "quiz-on-friday-project-3-input-data"
output_bucket = "quiz-on-friday-project-3-output-data"

test_cases = "test_cases/"

rgw_endpoint = "http://192.168.64.6:8080"

access_key = "useraccesskey"
secret_key = "usersecretkey"

file_name="test_0.csv"
# Specify the name of the bucket you want to create
def main():
    s3 = boto3.resource('s3',
                        endpoint_url=rgw_endpoint,
                        aws_access_key_id=access_key,
                        aws_secret_access_key=secret_key)

    bucket = s3.Bucket(output_bucket)

    bucket.download_file(Filename=file_name,
                         Key=file_name)


if __name__ == '__main__':
    main()
