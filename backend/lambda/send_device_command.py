import json
import boto3
import os
from datetime import datetime

IOT_ENDPOINT = os.environ.get(
    "IOT_ENDPOINT",
    "https://a3kjpfhb0sgn22-ats.iot.us-east-2.amazonaws.com"
)

iot_data_client = boto3.client(
    "iot-data",
    endpoint_url=IOT_ENDPOINT
)

def lambda_handler(event, context):
    try:
        print("EVENT:", json.dumps(event))

        path_params = event.get("pathParameters") or {}
        device_id = path_params.get("deviceId")

        if not device_id:
            return {
                "statusCode": 400,
                "headers": {
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*"
                },
                "body": json.dumps({"error": "deviceId es requerido"})
            }

        body = json.loads(event.get("body") or "{}")
        command = body.get("command")
        payload = body.get("payload", {})

        if not command:
            return {
                "statusCode": 400,
                "headers": {
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*"
                },
                "body": json.dumps({"error": "command es requerido"})
            }

        topic = f"orionseye/{device_id}/command"

        message = {
            "command": command,
            "payload": payload,
            "timestamp": datetime.utcnow().isoformat()
        }

        print(f"Publicando a topic: {topic}")
        print(f"Mensaje: {json.dumps(message)}")

        iot_data_client.publish(
            topic=topic,
            qos=1,
            payload=json.dumps(message)
        )

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({
                "success": True,
                "message": f'Comando "{command}" enviado',
                "deviceId": device_id,
                "topic": topic
            })
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({"error": str(e)})
        }