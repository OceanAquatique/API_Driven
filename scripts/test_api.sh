#!/usr/bin/env bash
set -euo pipefail

source .localstack-tp.env

echo "Test /status"
curl -s "$BASE_URL/status"; echo

echo "Test /stop"
curl -s "$BASE_URL/stop"; echo
sleep 2

echo "État EC2 après /stop"
awslocal ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[].Instances[].State.Name"

echo "Test /start"
curl -s "$BASE_URL/start"; echo
sleep 2

echo "État EC2 après /start"
awslocal ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[].Instances[].State.Name"
