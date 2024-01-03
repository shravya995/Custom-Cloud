# **Image Recognition Auto-Scaling App**
The Image Recognition Auto-scaling app was designed to auto-scale depending on the number of requests generated to AWS SQS. This is a manual auto-scaling service setup, and we have not used any particular auto-scaling features related AWS EC2 or any other services provided AWS. The complete project development was implemented on Amazon Web Services (AWS).

For the development of the app, the steps were taken in stages. We start with the initial AWS Management and setup for creating the service.

## **AWS Management and Service Setup**
The AWS management and service setup has multiple steps related to creating Identity and Access Management services, and more to come here.

## **IAM Services**
- Create an IAM user group which has the following permissions: AWS EC2 Full Access, AWS S3 Full Access, IAM Full Access. Refer this link for more details on IAM User Group Creation.
- Create an IAM user with the above created user group. Refer this link for more details on how to create IAM user.
- Create an IAM role that will be assigned to EC2 instances created by the web application which has the permissions to read, write and delete in particular S3 buckets.
- Refer this link how to create an IAM Role for a particular AWS service. For our use-case select EC2 while creating this IAM profile.
- The created IAM user and user group are essential to restrict access to AWS. This user credentials can be shared within the project group without worrying about incurring extra costs. The created IAM role will restrict access to S3 to whatever resource is essential instead of having complete access to S3.

## **S3 Services**
Create two buckets - Input Data Bucket and Output Data bucket with their own unique names. The input data bucket contains data that web app fetches and the output data bucket contains the output of the image recognition process.
