import json
import boto3
from datetime import datetime
from urllib.parse import unquote

IOT_REGION = "us-east-2"


def lambda_handler(event, context):
    try:
        print("Event:", json.dumps(event))

        # Path params: /devices/{deviceId}/command
        path_params = event.get("pathParameters") or {}
        device_id = path_params.get("deviceId") or path_params.get("deviceid")

        if not device_id:
            return _resp(400, {"error": "Missing deviceId"})

        device_id = unquote(device_id).strip()

        body = event.get("body") or "{}"
        if isinstance(body, str):
            try:
                body = json.loads(body)
            except Exception:
                body = {}

        # action default capture
        action = body.get("action", "capture")
        payload_in = body.get("payload", {}) or {}

        # Cliente IoT Data
        iot = boto3.client("iot-data", region_name=IOT_REGION)

        # ✅ Topic correcto para ESP32 subscriber
        topic = f"orionseye/{device_id}/command"

        payload = {
            "command": action,                         # <- ESP32 espera command
            "payload": payload_in,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "source": "api"
        }

        print(f"Publishing to topic: {topic}")
        print(f"Payload: {json.dumps(payload)}")

        iot.publish(
            topic=topic,
            qos=1,
            payload=json.dumps(payload)
        )

        print(f"Publicado a {topic}")

        return _resp(200, {
            "ok": True,
            "topic": topic,
            "payload": payload
        })

    except Exception as e:
        print("Error:", str(e))
        import traceback
        traceback.print_exc()
        return _resp(500, {"error": str(e)})


def _resp(code, body):
    return {
        "statusCode": code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
        },
        "body": json.dumps(body)
    }