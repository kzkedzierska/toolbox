#!/bin/bash

# Usage function
usage() {
  echo "Usage: $0 --instance-id <id> --max-retries <num> --retry-delay <sec> [--profile <aws-profile>]"
  echo "Example: $0 --instance-id i-xxxxxxxxxxxx --max-retries 20 --retry-delay 30 --profile my-profile"
  exit 1
}

# Default values
AWS_PROFILE="default"

# Parse command-line arguments
while (("$#")); do
  case "$1" in
  --instance-id | -i)
    INSTANCE_ID=$2
    shift 2
    ;;
  --max-retries | -r)
    MAX_RETRIES=$2
    shift 2
    ;;
  --retry-delay | -d)
    RETRY_DELAY=$2
    shift 2
    ;;
  --profile | -p)
    AWS_PROFILE=$2
    shift 2
    ;;
  --avail-zone | -z)
    AVAIL_ZONE=$2
    shift 2
    ;;
  --help | -h)
    usage
    ;;
  --) # end argument parsing
    shift
    break
    ;;
  -* | --*=) # unsupported flags
    echo "Error: Unsupported flag $1"
    usage
    ;;
  *) # preserve positional arguments
    PARAMS="$PARAMS $1"
    shift
    ;;
  esac
done

# Ensure required arguments are provided
if [[ -z "$INSTANCE_ID" || -z "$MAX_RETRIES" || -z "$RETRY_DELAY" ]]; then
  echo "Error: Missing required arguments"
  usage
fi

# AWS CLI command setup
AWS_CMD="aws --profile $AWS_PROFILE"

if [[ -n "$AVAIL_ZONE" ]]; then
  INSTANCE_AZ=$($AWS_CMD ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "Reservations[].Instances[].Placement.AvailabilityZone" --output text)

  if [[ "$INSTANCE_AZ" != "$AVAIL_ZONE"-* ]]; then
    echo "Error: Instance is in $INSTANCE_AZ, not in the us-west region!"
    exit 1
  fi
fi

# Retry loop
for ((i = 1; i <= MAX_RETRIES; i++)); do
  echo "Attempt $i: Trying to start instance $INSTANCE_ID using profile '$AWS_PROFILE'..."

  # Try starting the instance
  RESPONSE=$($AWS_CMD ec2 start-instances --instance-ids "$INSTANCE_ID" 2>&1)

  # Check if the response contains a capacity error
  if echo "$RESPONSE" | grep -q "InsufficientInstanceCapacity"; then
    echo "Capacity issue, retrying in $RETRY_DELAY seconds..."
    sleep "$RETRY_DELAY"
  else
    echo "Instance started successfully!"
    exit 0
  fi
done

echo "Failed to start the instance after $MAX_RETRIES attempts."
exit 1
