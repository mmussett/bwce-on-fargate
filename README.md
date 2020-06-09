

# BWCE on AWS Fargate

## Build the Enterrise Application Resource (EAR)

$ cd src/TripStatusAPI/TripStatusAPI
$ mvn clean; mvn package

## Copy the EAR to the package folder

$ cp ../TripStatusAPI/target/TripStatusAPI_1.0.0.ear ../../../package/.

## Build the docker image

$ docker build -t tripstatus:latest .

## Run the container
docker run -p 8080:8080 -p 7777:7777 -it tripstatus:latest


## Create ECR in AWS

Create a repository in ECE to push our image to:

$ aws ecr create-repository --repository-name tripstatus


## Describe the repositories to get registryId

$ aws ecr describe-repositories | jq '.repositories[] | {name: .repositoryName, uri: .repositoryUri}'

```
{
  "name": "tripstatus",
  "uri": "696093067220.dkr.ecr.eu-west-1.amazonaws.com/tripstatus"
}
```

## Authenticate Docker against ECR 

$ aws ecr get-login-password \
    --region eu-west-1 \
    | docker login \
    --username AWS \
    --password-stdin 696093067220.dkr.ecr.eu-west-1.amazonaws.com/tripstatus

```
Login Succeeded
```


## Tag the container

$ docker tag tripstatus:latest 696093067220.dkr.ecr.eu-west-1.amazonaws.com/tripstatus

## Push the container image to AWS ECR repository

$ docker push 696093067220.dkr.ecr.eu-west-1.amazonaws.com/tripstatus:latest


## Create the AWS infrastructure

$ tf plan
$ tf apply

## Find DNS address of the ALB

$ aws elbv2 describe-load-balancers | jq '.LoadBalancers[] | {DNS: .DNSName}'

## Test application

Wait 60 seconds for the container to be ready

curl -X GET --header 'Accept: application/json' 'http://mm-bwce-fargate-lb-1588994854.eu-west-1.elb.amazonaws.com:8080/trips'
