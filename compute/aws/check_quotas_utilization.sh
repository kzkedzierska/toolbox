#!/bin/bash

# Default AWS profile
AWS_PROFILE="default"

# Function to print usage
usage() {
  echo "Usage: $0 [-p|--profile <aws-profile>]"
  echo "Options:"
  echo "  -p, --profile    AWS profile to use (default: 'default')"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  -p | --profile)
    AWS_PROFILE="$2"
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown option: $1"
    usage
    exit 1
    ;;
  esac
done

echo "Getting list of all AWS regions..."
REGIONS=$(aws ec2 describe-regions --profile "$AWS_PROFILE" --query 'Regions[].RegionName' --output text)

total_vcpus=0

echo "Checking running instances in each region..."
echo "----------------------------------------"

for region in $REGIONS; do
  echo "Region: $region"

  # Get running instances in the region
  INSTANCES=$(aws ec2 describe-instances \
    --profile "$AWS_PROFILE" \
    --region "$region" \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].[InstanceId,InstanceType,Placement.AvailabilityZone,Tags[?Key==`Name`].Value | [0]]' \
    --output text)

  if [ -n "$INSTANCES" ]; then
    # For each instance, get its vCPU count
    while IFS=$'\t' read -r instance_id instance_type az name; do
      # Get vCPU count for instance type
      vcpu_count=$(aws ec2 describe-instance-types \
        --profile "$AWS_PROFILE" \
        --region "$region" \
        --instance-types "$instance_type" \
        --query 'InstanceTypes[].VCpuInfo.DefaultVCpus' \
        --output text)

      # Add to total
      total_vcpus=$((total_vcpus + vcpu_count))

      # Print instance details
      printf "  InstanceID: %s\n" "$instance_id"
      printf "  Type: %s (vCPUs: %s)\n" "$instance_type" "$vcpu_count"
      printf "  AZ: %s\n" "$az"
      if [ -n "$name" ]; then
        printf "  Name: %s\n" "$name"
      fi
      echo "  ----------------------------------------"
    done <<<"$INSTANCES"
  else
    echo "  No running instances"
    echo "  ----------------------------------------"
  fi
done

echo "Total vCPUs in use across all regions: $total_vcpus"

# Additionally, let's check for any active Capacity Reservations
echo -e "\nChecking active Capacity Reservations across regions..."
echo "----------------------------------------"

for region in $REGIONS; do
  echo "Region: $region"

  RESERVATIONS=$(aws ec2 describe-capacity-reservations \
    --profile "$AWS_PROFILE" \
    --region "$region" \
    --filters "Name=state,Values=active" \
    --query 'CapacityReservations[].[CapacityReservationId,InstanceType,AvailabilityZone,TotalInstanceCount]' \
    --output text)

  if [ -n "$RESERVATIONS" ]; then
    while IFS=$'\t' read -r res_id instance_type az count; do
      # Get vCPU count for instance type
      vcpu_count=$(aws ec2 describe-instance-types \
        --profile "$AWS_PROFILE" \
        --region "$region" \
        --instance-types "$instance_type" \
        --query 'InstanceTypes[].VCpuInfo.DefaultVCpus' \
        --output text)

      total_res_vcpus=$((vcpu_count * count))

      printf "  ReservationID: %s\n" "$res_id"
      printf "  Type: %s (vCPUs per instance: %s)\n" "$instance_type" "$vcpu_count"
      printf "  AZ: %s\n" "$az"
      printf "  Instance Count: %s (Total vCPUs: %s)\n" "$count" "$total_res_vcpus"
      echo "  ----------------------------------------"
    done <<<"$RESERVATIONS"
  else
    echo "  No active capacity reservations"
    echo "  ----------------------------------------"
  fi
done
