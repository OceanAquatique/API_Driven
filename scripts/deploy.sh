#!/usr/bin/env bash
set -euo pipefail

export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

curl -fs http://localhost:4566/_localstack/health >/dev/null

INSTANCE_ID=$(awslocal ec2 run-instances \
  --image-id ami-12345678 \
  --instance-type t2.micro \
  --query 'Instances[0].InstanceId' \
  --output text)

zip -q function.zip lambda_function.py

cat > trust-policy.json <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
JSON

if ! awslocal iam get-role --role-name lambda-ec2-control-role >/dev/null 2>&1; then
  awslocal iam create-role \
    --role-name lambda-ec2-control-role \
    --assume-role-policy-document file://trust-policy.json >/dev/null
fi

if awslocal lambda get-function --function-name ec2-control >/dev/null 2>&1; then
  awslocal lambda update-function-code \
    --function-name ec2-control \
    --zip-file fileb://function.zip >/dev/null

  awslocal lambda update-function-configuration \
    --function-name ec2-control \
    --environment "Variables={INSTANCE_ID=$INSTANCE_ID}" >/dev/null
else
  awslocal lambda create-function \
    --function-name ec2-control \
    --runtime python3.12 \
    --handler lambda_function.lambda_handler \
    --role arn:aws:iam::000000000000:role/lambda-ec2-control-role \
    --zip-file fileb://function.zip \
    --environment "Variables={INSTANCE_ID=$INSTANCE_ID}" \
    --timeout 30 >/dev/null
fi

awslocal lambda wait function-active-v2 --function-name ec2-control

API_ID=$(awslocal apigateway create-rest-api \
  --name "ec2-control-api" \
  --query 'id' \
  --output text)

ROOT_ID=$(awslocal apigateway get-resources \
  --rest-api-id "$API_ID" \
  --query 'items[0].id' \
  --output text)

RESOURCE_ID=$(awslocal apigateway create-resource \
  --rest-api-id "$API_ID" \
  --parent-id "$ROOT_ID" \
  --path-part "{action}" \
  --query 'id' \
  --output text)

awslocal apigateway put-method \
  --rest-api-id "$API_ID" \
  --resource-id "$RESOURCE_ID" \
  --http-method GET \
  --request-parameters "method.request.path.action=true" \
  --authorization-type "NONE" >/dev/null

awslocal apigateway put-integration \
  --rest-api-id "$API_ID" \
  --resource-id "$RESOURCE_ID" \
  --http-method GET \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:ec2-control/invocations \
  --passthrough-behavior WHEN_NO_MATCH >/dev/null

awslocal lambda add-permission \
  --function-name ec2-control \
  --statement-id "apigateway-invoke-$API_ID" \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:000000000000:$API_ID/*/GET/*" >/dev/null

awslocal apigateway create-deployment \
  --rest-api-id "$API_ID" \
  --stage-name dev >/dev/null

cat > .localstack-tp.env <<EOF
INSTANCE_ID=$INSTANCE_ID
API_ID=$API_ID
BASE_URL=http://localhost:4566/_aws/execute-api/$API_ID/dev
EOF

echo "Déploiement terminé."
echo "Instance EC2 : $INSTANCE_ID"
echo "API Gateway : http://localhost:4566/_aws/execute-api/$API_ID/dev"
echo "Routes disponibles : /status, /stop, /start"
