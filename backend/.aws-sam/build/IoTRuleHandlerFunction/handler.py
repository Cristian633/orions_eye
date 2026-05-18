import json
import os
import uuid
import boto3
from datetime import datetime

lambda_client = boto3.client("lambda")
dynamodb = boto3.resource("dynamodb")

devices_table = dynamodb.Table(os.environ["DEVICES_TABLE"])
observations_table = dynamodb.Table(os.environ["OBSERVATIONS_TABLE"])
S3_BUCKET = os.environ["S3_BUCKET"]


def lambda_handler(event, context):
    """
    Maneja mensajes MQTT del ESP32 vía IoT Rules
    Topics:
      - orionseye/{deviceId}/image
      - orionseye/{deviceId}/status
      - orionseye/{deviceId}/data
      - orionseye/{deviceId}/image-uploaded
    """
    try:
        print(f"Mensaje IoT recibido: {json.dumps(event)}")

        topic = event.get("topic", "")
        message = event

        parts = topic.split("/")
        device_id = parts[1] if len(parts) > 1 else None
        topic_type = parts[2] if len(parts) > 2 else None

        # Fallback: deviceId desde payload si no viene en el topic
        if not device_id:
            device_id = message.get("deviceId")
            if not device_id:
                print("No se pudo extraer deviceId del topic ni del payload")
                return {"statusCode": 400, "body": "Missing deviceId"}

        # Determinar tipo de mensaje
        if topic_type == "image":
            print(f"Procesando imagen del dispositivo: {device_id}")

            lambda_client.invoke(
                FunctionName="orions-eye-process-image-dev",
                InvocationType="Event",
                Payload=json.dumps(
                    {
                        "deviceId": device_id,
                        "imageData": message.get("imageData"),
                        "imageS3Key": message.get("imageS3Key"),
                        "userId": message.get("userId"),
                        "timestamp": message.get(
                            "timestamp", datetime.utcnow().isoformat()
                        ),
                    }
                ),
            )

            print("Lambda de procesamiento invocada")

        elif topic_type == "image-uploaded":
            print(f"Imagen subida recibida: {device_id}")

            s3_key = message.get("s3Key") or message.get("imageS3Key")
            if not s3_key:
                return {"statusCode": 400, "body": "Missing s3Key"}

            # Resolver userId desde tabla devices si no viene en el payload
            user_id = message.get("userId")
            if not user_id:
                dev = devices_table.get_item(Key={"deviceId": device_id}).get("Item")
                user_id = (dev or {}).get("userId", "unknown")

            observation_id = str(uuid.uuid4())
            now_iso = datetime.utcnow().isoformat() + "Z"
            image_url = f"https://{S3_BUCKET}.s3.us-east-2.amazonaws.com/{s3_key}"

            observations_table.put_item(
                Item={
                    "observationId": observation_id,
                    "deviceId": device_id,
                    "userId": user_id,
                    "timestamp": now_iso,
                    "s3Key": s3_key,
                    "imageUrl": image_url,
                    "result": "uploaded",
                }
            )

            print(f"Observación creada: {observation_id}")

        elif topic_type == "status":
            print(f"Actualizando estado: {device_id}")
            update_device_status(device_id, message)

        elif topic_type == "data":
            print(f"Datos de sensores: {device_id}")
            save_sensor_data(device_id, message)

        return {"statusCode": 200, "body": json.dumps({"message": "Processed"})}

    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback

        traceback.print_exc()
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}


def update_device_status(device_id, message):
    """Actualiza el estado del dispositivo en DynamoDB"""
    try:
        devices_table.update_item(
            Key={"deviceId": device_id},
            UpdateExpression="SET #status = :status, lastUpdate = :timestamp, isOnline = :online",
            ExpressionAttributeNames={"#status": "status"},
            ExpressionAttributeValues={
                ":status": message.get("status", "online"),
                ":timestamp": datetime.utcnow().isoformat(),
                ":online": True,
            },
        )
        print(f"Estado actualizado para {device_id}")
    except Exception as e:
        print(f"Error actualizando estado: {e}")


def save_sensor_data(device_id, message):
    """Guarda datos de sensores adicionales"""
    print(f"💾 Guardando datos de sensores: {message}")