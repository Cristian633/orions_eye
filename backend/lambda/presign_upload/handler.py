import json
import os
import boto3
from datetime import datetime, timezone
import uuid

s3 = boto3.client("s3")
BUCKET = os.environ["S3_BUCKET"]

def lambda_handler(event, context):
    # usuario desde Cognito
    user_id = event["requestContext"]["authorizer"]["claims"]["sub"]

    body = json.loads(event.get("body") or "{}")
    device_id = body.get("deviceId", "unknown-device")
    content_type = body.get("contentType", "image/jpeg")

    # key único
    ts = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    obs_id = str(uuid.uuid4())
    key = f"observations/{user_id}/{device_id}/{ts}_{obs_id}.jpg"

    upload_url = s3.generate_presigned_url(
        ClientMethod="put_object",
        Params={
            "Bucket": BUCKET,
            "Key": key,
            "ContentType": content_type,
        },
        ExpiresIn=300,  # 5 min
    )

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps({
            "uploadUrl": upload_url,
            "s3Key": key,
            "bucket": BUCKET,
            "expiresIn": 300,
        })
    }