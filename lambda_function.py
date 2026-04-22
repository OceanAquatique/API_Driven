import json
import os
import boto3

INSTANCE_ID = os.environ["INSTANCE_ID"]

ec2 = boto3.client(
    "ec2",
    region_name=os.environ.get("AWS_REGION", "us-east-1"),
    endpoint_url=os.environ.get("AWS_ENDPOINT_URL")
)

def lambda_handler(event, context):
    path_params = event.get("pathParameters") or {}
    query_params = event.get("queryStringParameters") or {}

    action = path_params.get("action") or query_params.get("action")

    if action not in ["start", "stop", "status"]:
        return {
            "statusCode": 400,
            "body": json.dumps({
                "message": "Action invalide. Utilise /start, /stop ou /status."
            })
        }

    if action == "start":
        ec2.start_instances(InstanceIds=[INSTANCE_ID])
        message = f"Instance {INSTANCE_ID} démarrée."

    elif action == "stop":
        ec2.stop_instances(InstanceIds=[INSTANCE_ID])
        message = f"Instance {INSTANCE_ID} arrêtée."

    else:
        response = ec2.describe_instances(InstanceIds=[INSTANCE_ID])
        state = response["Reservations"][0]["Instances"][0]["State"]["Name"]
        message = f"Instance {INSTANCE_ID} état actuel : {state}."

    return {
        "statusCode": 200,
        "body": json.dumps({
            "action": action,
            "instance_id": INSTANCE_ID,
            "message": message
        })
    }
