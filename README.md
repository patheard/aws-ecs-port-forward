# AWS ECS task connect with SSM port forwarding
Connect to a private ECS test using SSM Session Manager port forwarding.

## Requirements
- AWS CLI
- [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)

## Connect
```sh
aws ssm start-session --target ecs:<CLUSTER>_<TASK ID>_<CONTAINER_RUNTIME_ID> --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["80"], "localPortNumber":["1338"]}' --region ca-central-1

# Example
aws ssm start-session --target ecs:internal_ad87713568a9469b8bb056780a2e1ffd_ad87713568a9469b8bb056780a2e1ffd-3386804179 --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["80"], "localPortNumber":["1338"]}' --region ca-central-1
```

# Credit
Most of this is taking from [@mohamed-cds's example](https://github.com/mohamed-cds/terraform_test_infrastructure/tree/main/ssm_private_subnet/terraform), with the addition of using only VPC PrivateLinks to run the ECS task.