#!/bin/bash

# Configuration
MAX_RETRIES=10
RETRY_DELAY=30 # seconds
INSTANCE_TYPE="g6.12xlarge"
AVAILABILITY_ZONE="us-west-2d"
INSTANCE_PLATFORM="Linux/UNIX"
INSTANCE_COUNT=1
AUTOMATED_END_DATE=false
END_DATE=
TENANCY="default"

# Default AWS profile
AWS_PROFILE="default"

# Function to print usage
usage() {
  echo "Usage: $0 -p <aws-profile> -t <instance-type> -a <availability-zone> -i <instance-platform> -c <instance-count> -d <retry-delay>"

}

# Function to get date in ISO8601 format
get_future_date() {
  local days=$1
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS version
    date -u -v+${days}d +%Y-%m-%dT%H:%M:%SZ
  else
    # GNU/Linux version
    date -u -d "+${days} days" +%Y-%m-%dT%H:%M:%SZ
  fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  -p | --profile)
    AWS_PROFILE="$2"
    shift 2
    ;;
  --instance-type)
    INSTANCE_TYPE="$2"
    shift 2
    ;;
  -a | --availability-zone)
    AVAILABILITY_ZONE="$2"
    shift 2
    ;;
  --instance-platform)
    INSTANCE_PLATFORM="$2"
    shift 2
    ;;
  -c | --instance-count)
    INSTANCE_COUNT="$2"
    shift 2
    ;;
  -d | --retry-delay)
    RETRY_DELAY="$2"
    shift 2
    ;;
  -m | --max-retries)
    MAX_RETRIES="$2"
    shift 2
    ;;
  -t | --tenancy)
    TENANCY="$2"
    shift 2
    ;;
  -d | --days)
    AUTOMATED_END_DATE=true
    END_DATE=$(get_future_date "$2")
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

# check if tenancy is valid
if [[ "$TENANCY" != "default" && "$TENANCY" != "dedicated" ]]; then
  echo "Invalid tenancy option. Use 'default' or 'dedicated'."
  exit 1
fi

# check if instance count is valid
if ! [[ "$INSTANCE_COUNT" =~ ^[0-9]+$ ]]; then
  echo "Invalid instance count. Must be a positive integer."
  exit 1
fi

create_reservation() {
  local attempt=1
  # Build the AWS CLI command dynamically
  CMD="aws ec2 create-capacity-reservation \
            --profile \"$AWS_PROFILE\" \
            --instance-type \"$INSTANCE_TYPE\" \
            --instance-platform \"$INSTANCE_PLATFORM\" \
            --availability-zone \"$AVAILABILITY_ZONE\" \
            --instance-count $INSTANCE_COUNT \
            --instance-match-criteria \"open\" \
            --tenancy \"$TENANCY\""

  # Add end date parameters if specified
  if [ "$AUTOMATED_END_DATE" = true ]; then
    CMD="$CMD --end-date-type \"limited\" --end-date \"$END_DATE\""
  else
    CMD="$CMD --end-date-type \"unlimited\""
  fi

  # Add EBS optimization
  CMD="$CMD --ebs-optimized"

  while [ $attempt -le $MAX_RETRIES ]; do
    echo "Attempt $attempt of $MAX_RETRIES to create capacity reservation using profile: $AWS_PROFILE..."

    # Execute the command
    RESPONSE=$(eval "$CMD" 2>&1)

    # Check if the command was successful
    if [ $? -eq 0 ]; then
      echo "Successfully created capacity reservation!"
      echo "$RESPONSE"
      return 0
    else
      # Check if error is capacity-related
      if echo "$RESPONSE" | grep -q "InsufficientInstanceCapacity\|capacity-not-available"; then
        echo "Capacity not available. Retrying in $RETRY_DELAY seconds..."
        sleep $RETRY_DELAY
        attempt=$((attempt + 1))
      elif echo "$RESPONSE" | grep -q "InstanceLimitExceeded"; then
        echo "Instance limit exceeded. Please check your limits and try again."
        sleep $RETRY_DELAY
        attempt=$((attempt + 1))
      else
        # If it's a different error, show it and exit
        echo "Error creating capacity reservation:"
        echo "$RESPONSE"
        return 1
      fi
    fi
  done

  echo "Failed to create capacity reservation after $MAX_RETRIES attempts"
  return 1
}

# Main script execution
echo "Starting capacity reservation creation process with AWS profile: $AWS_PROFILE"
create_reservation

# Check final result
if [ $? -eq 0 ]; then
  echo "Script completed successfully"
else
  echo "Script failed to create capacity reservation"
  exit 1
fi
