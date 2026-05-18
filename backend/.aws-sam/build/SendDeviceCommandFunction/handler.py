import json
import os
import boto3
from datetime import datetime

def lambda_handler(event, context):
    try:
        print("Event:", json.dumps(event))

        # Path params: /devices/{deviceId}/command
        device_id = event.get("pathParameters", {}).get("deviceid") or \
                    event.get("pathParameters", {}).get("deviceId")

        if not device_id:
            return {"statusCode": 400, "body": "Missing deviceId"}

        body = event.get("body") or "{}"
        if isinstance(body, str):
            body = json.loads(body)

        action = body.get("action", "capture")

        iot_endpoint = os.environ["IOT_DATA_ENDPOINT"]
        iot = boto3.client("iot-data", endpoint_url=f"https://{iot_endpoint}")

        topic = f"orionseye/{device_id}/capture"
        payload = {
            "action": action,
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }

        iot.publish(topic=topic, qos=0, payload=json.dumps(payload))
        print(f"Publicado a {topic}")

        return {
            "statusCode": 200,
            "body": json.dumps({"ok": True, "topic": topic, "payload": payload})
        }

    except Exception as e:
        print("Error:", str(e))
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}