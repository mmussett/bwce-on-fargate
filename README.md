

# Pushing Your Docker Image to AWS ECR

## 1. Create ECR in AWS

Create a repository in ECE to push our image to:

$ aws ecr create-repository --repository-name tripstatus


## Describe the repositories to get registryId

$ aws ecr describe-repositories | jq '.repositories[] | {name: .repositoryName, uri: .repositoryUri}'

```
{
  "name": "tripstatus",
  "uri": "091505477228.dkr.ecr.eu-west-1.amazonaws.com/tripstatus"
}
```

## Authenticate Docker against ECR 

$ aws ecr get-login-password \
    --region eu-west-1 \
    | docker login \
    --username AWS \
    --password-stdin 091505477228.dkr.ecr.eu-west-1.amazonaws.com/tripstatus


Login Succeeded



## Build the docker image

$ docker build -t tripstatus:latest .


## Tag the container

$ docker tag tripstatus:latest 091505477228.dkr.ecr.eu-west-1.amazonaws.com/tripstatus:latest


## Push the container image to AWS ECR repository

$ docker push 091505477228.dkr.ecr.eu-west-1.amazonaws.com/tripstatus:latest


## 4. Run the container
docker run -p 8080:8080 -it tripstatus:latest


