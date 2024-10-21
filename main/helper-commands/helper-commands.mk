aws eks create-fargate-profile \
    --cluster-name MyEKSCluster \
    --fargate-profile-name MyFargateProfile \
    --pod-execution-role-arn arn:aws:iam::058264080215:role/EKS-EXAMPLE-PodExecutionRole-Gy44xwSKXvsI \
    --subnets subnet-0b8677c962dcd0a72 subnet-0dbd24c4324bc2598 \
    --selectors '[{"namespace":"kube-system"},{"namespace":"demo"}]'

aws eks delete-fargate-profile \
    --cluster-name MyEKSCluster \
    --fargate-profile-name MyFargateProfile

aws eks list-fargate-profiles --cluster-name MyEKSCluster 
kubectl rollout restart deployment/coredns -n kube-system


subnet-0b8677c962dcd0a72 subnet-0dbd24c4324bc2598

aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-0f6beb4d60850faeb"

#############################################################################################################
# COMANDS USED FOR TROUBLESHOOTING EKS CREATION AND THEIR CONFIGURATION

# CREATE A EKS CLUSTER
aws eks create-cluster \
    --name MyEKSCluster \
    --role-arn arn:aws:iam::<your-account-id>:role/<your-eks-role> \
    --resources-vpc-config subnetIds=subnet-12345678,subnet-87654321,securityGroupIds=sg-12345678

# CREATE FARGATE PROFILE
aws eks create-fargate-profile \
    --cluster-name MyEKSCluster \
    --fargate-profile-name MyFargateProfile \
    --pod-execution-role-arn arn:aws:iam::<your-account-id>:role/<your-pod-execution-role> \
    --subnets subnet-12345678 subnet-87654321 \
    --selectors namespace=kube-system

# UPDATE THE FARGATE PROFILE
aws eks update-fargate-profile \
    --cluster-name MyEKSCluster \
    --fargate-profile-name MyFargateProfile \
    --selectors namespace=<new-namespace>
# NOTE: THIS DON'T WORK, TRY IT BW MAYBE WORK FOR U

# DESCRIBE THE EKS CLUSTER
aws eks describe-cluster --name MyEKSCluster

# CHECK POD STATUS
kubectl get pods -n kube-system

# SET UP AN IGW
# Resources:
#   InternetGateway:
#     Type: AWS::EC2::InternetGateway

# ATTACH THE IGW TO VPC
# VPCGatewayAttachment:
#   Type: AWS::EC2::VPCGatewayAttachment
#   Properties:
#     VpcId: !Ref VPC
#     InternetGatewayId: !Ref InternetGateway

# CREATE ROUTE TABLES
# PublicRouteTable:
#   Type: AWS::EC2::RouteTable
#   Properties:
#     VpcId: !Ref VPC

# CREATE A ROUTE TO THE IGW
# PublicRouteToIGW:
#   Type: AWS::EC2::Route
#   Properties:
#     RouteTableId: !Ref PublicRouteTable
#     DestinationCidrBlock: 0.0.0.0/0
#     GatewayId: !Ref InternetGateway

# SET THE MAIN ROUTE TABLE
aws ec2 associate-route-table --route-table-id <PublicRouteTableId> --vpc-id <VPCId>

# GET CLUSTER POD CONFIGURATION
kubectl get pods -o yaml -n kube-system

# CHECK IMAGE PULL ERRORS
kubectl describe pod <pod-name> -n <namespace>

# CREATE IAM ROLE FOR FARGATE
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks-fargate.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}

