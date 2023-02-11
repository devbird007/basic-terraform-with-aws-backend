# terraform-aws-webapp-with-aws-backend
This is a project to provision aws resources with terraform, but store the state files in aws backend along with encryption and state-locking via DynamoDB.
Take the following steps after you Clone this repository

### Backend Resources
Run the main.tf file in the aws-backend folder to create the backend resources which are an s3 bucket and a dynamodb table along with their configurations.
Now, uncomment the backend block and rerun the main.tf file again to transfer the state files to the newly created s3 bucket.
This will be where the state files will be stored for the rest of this project.


### Provision Your Desired Resources
![Architecture Diagram](architecture.png)

The main.tf file in the web-app folder will provision the resources in the aws resources architecture diagram above and send the state files directly to the backend s3 bucket created above.

### Test
You can test the instances by entering the generated IP addresses in your web browser of choice. 
A web-page written in python will be displayed.
