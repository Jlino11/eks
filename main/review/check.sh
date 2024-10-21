#!/bin/bash

# Variables
NAMESPACE="default" # Change to your namespace if needed

# Check AWS CLI and kubectl installation
if ! command -v aws &> /dev/null || ! command -v kubectl &> /dev/null; then
    echo "AWS CLI and kubectl must be installed."
    exit 1
fi

# Get EKS Cluster Name
CLUSTER_NAME=$(aws eks list-clusters --query "clusters[0]" --output text)

if [ "$CLUSTER_NAME" == "None" ]; then
    echo "No EKS clusters found. Please check your AWS configuration."
    exit 1
fi

echo "Reviewing EKS Cluster: $CLUSTER_NAME"

# 1. Check EKS Cluster Status
CLUSTER_STATUS=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query "cluster.status" --output text)
if [ "$CLUSTER_STATUS" != "ACTIVE" ]; then
    echo "EKS Cluster status: $CLUSTER_STATUS. Please ensure it is ACTIVE."
fi

# 2. Check Fargate Profiles
FARGATE_PROFILES=$(aws eks list-fargate-profiles --cluster-name "$CLUSTER_NAME" --query "fargateProfileNames" --output text)
if [ -z "$FARGATE_PROFILES" ]; then
    echo "No Fargate profiles found. Make sure your pods are set to run on Fargate."
else
    echo "Fargate Profiles: $FARGATE_PROFILES"
fi

# 3. Check IAM Roles
echo "Checking IAM Roles..."
POD_EXEC_ROLE=$(kubectl get fargateprofile -n kube-system -o jsonpath='{.items[*].podExecutionRoleArn}')
if [ -z "$POD_EXEC_ROLE" ]; then
    echo "No Pod Execution Role found for Fargate profile."
else
    echo "Pod Execution Role: $POD_EXEC_ROLE"
fi

# 4. Check Pods and their Status
echo "Checking Pods in namespace '$NAMESPACE'..."
kubectl get pods -n "$NAMESPACE"
kubectl get events -n "$NAMESPACE"

# 5. Check for image pull errors
echo "Checking for Image Pull Errors..."
kubectl get pods -n "$NAMESPACE" --field-selector=status.phase!=Running -o json | jq -r '.items[] | select(.status.containerStatuses[0].state.waiting.reason=="ImagePullBackOff" or .status.containerStatuses[0].state.waiting.reason=="ErrImagePull") | .metadata.name'

# 6. Check CoreDNS Status
echo "Checking CoreDNS Status..."
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl describe pod -n kube-system -l k8s-app=kube-dns

# 7. Check Network Configuration
echo "Checking Network Configuration..."
VPC_ID=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query "cluster.resourcesVpcConfig.vpcId" --output text)
echo "VPC ID: $VPC_ID"
aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --query "Vpcs[].{CIDR:CidrBlock, State:State}"

# Summary
echo "EKS Configuration review completed."
