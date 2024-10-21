#!/bin/bash

# Variables
NAMESPACE="default" # Change to your namespace if needed
CLUSTER_NAME=$(aws eks list-clusters --query "clusters[0]" --output text)

# Function to check IAM Role and Policy
check_iam_role() {
    local role_name=$1
    local policy_name=$2

    if ! aws iam get-role --role-name "$role_name" &> /dev/null; then
        echo "ERROR: IAM role '$role_name' does not exist."
    else
        echo "IAM role '$role_name' exists."
    fi

    if ! aws iam list-attached-role-policies --role-name "$role_name" | grep "$policy_name" &> /dev/null; then
        echo "ERROR: Policy '$policy_name' is not attached to role '$role_name'."
    else
        echo "Policy '$policy_name' is attached to role '$role_name'."
    fi
}

# Check AWS CLI and kubectl installation
if ! command -v aws &> /dev/null || ! command -v kubectl &> /dev/null; then
    echo "AWS CLI and kubectl must be installed."
    exit 1
fi

# Check if EKS cluster exists
if [ "$CLUSTER_NAME" == "None" ]; then
    echo "No EKS clusters found. Please check your AWS configuration."
    exit 1
fi

echo "Reviewing EKS Cluster: $CLUSTER_NAME"

# Check for Fargate Profile
FARGATE_PROFILES=$(aws eks list-fargate-profiles --cluster-name "$CLUSTER_NAME" --query "fargateProfileNames" --output text)
if [ -z "$FARGATE_PROFILES" ]; then
    echo "ERROR: No Fargate profiles found for cluster '$CLUSTER_NAME'."
else
    echo "Fargate Profiles: $FARGATE_PROFILES"
fi

# Check Pod Execution Role
EXECUTION_ROLE="your-execution-role" # Replace with your actual execution role name
EXECUTION_POLICY="PodExecutionPolicy" # Replace with your actual execution policy name
check_iam_role "$EXECUTION_ROLE" "$EXECUTION_POLICY"

# Check Pods and their Status
echo "Checking Pods in namespace '$NAMESPACE'..."
kubectl get pods -n "$NAMESPACE"
kubectl get events -n "$NAMESPACE"

# Check for image pull errors
echo "Checking for Image Pull Errors..."
kubectl get pods -n "$NAMESPACE" --field-selector=status.phase!=Running -o json | jq -r '.items[] | select(.status.containerStatuses[0].state.waiting.reason=="ImagePullBackOff" or .status.containerStatuses[0].state.waiting.reason=="ErrImagePull") | .metadata.name'

# Check CoreDNS Status
echo "Checking CoreDNS Status..."
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl describe pod -n kube-system -l k8s-app=kube-dns

# Summary
echo "EKS Configuration review completed."
