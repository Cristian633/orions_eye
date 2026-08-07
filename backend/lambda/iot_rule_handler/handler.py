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
ENVIRONMENT = os.environ.get("ENVIRONMENT", "dev")


def _extract_topic(event: dict) -> str:
    """Extrae topic desde distintos nombres posibles."""
    return event.get("topic") or event.get("topicName") or event.get("mqttTopic") or ""


def _extract_device_and_type(topic: str):
    """
    Espera topic con formato:
    orionseye/{deviceId}/{type}
    """
    if not topic:
        return None, None

    parts = topic.split("/")
    if len(parts) >= 3 and parts[0] == "orionseye":
        return parts[1], parts[2]
    return None, None


def lambda_handler(event, context):
    """
    Maneja mensajes MQTT del ESP32 vía IoT Rules.
    Topics soportados:
      - orionseye/{deviceId}/capture
      - orionseye/{deviceId}/image
      - orionseye/{deviceId}/image-uploaded
      - orionseye/{deviceId}/status
      - orionseye/{deviceId}/data
    """
    try:
        if isinstance(event, str):
            event = json.loads(event)

        if not isinstance(event, dict):
            print("Evento no es dict")
            return {"statusCode": 400, "body": "Invalid event type"}

        print(f"Mensaje IoT recibido: {json.dumps(event)}")

        topic = _extract_topic(event)
        message = event

        device_id, topic_type = _extract_device_and_type(topic)

        # Fallback deviceId desde payload
        if not device_id:
            device_id = message.get("deviceId") or message.get("device_id")

        # Fallback topic_type si no viene en topic
        if not topic_type and message.get("action") == "capture":
            topic_type = "capture"

        if not device_id:
            print("No se pudo extraer deviceId del topic ni del payload")
            return {"statusCode": 400, "body": "Missing deviceId"}

        print(f"Topic detectado: {topic} | device_id={device_id} | topic_type={topic_type}")

        # 1) Capture: SOLO ACK / LOG (NO invocar process-image aquí)
        if topic_type == "capture":
            print(f"Evento capture recibido (ack): {device_id}")
            return {"statusCode": 200, "body": json.dumps({"message": "capture ack"})}

        # 2) Image: aquí sí se procesa
        elif topic_type == "image":
            print(f"Procesando imagen del dispositivo: {device_id}")

            image_data = message.get("imageData")
            image_s3_key = message.get("imageS3Key") or message.get("s3Key")

            if not image_data and not image_s3_key:
                print("Mensaje image sin imageData/imageS3Key, se ignora")
                return {"statusCode": 200, "body": json.dumps({"message": "ignored empty image"})}

            process_fn = f"orions-eye-process-image-{ENVIRONMENT}"
            payload = {
                "deviceId": device_id,
                "imageData": image_data,
                "imageS3Key": image_s3_key,
                "userId": message.get("userId"),
                "timestamp": message.get("timestamp", datetime.utcnow().isoformat() + "Z"),
                "topic": topic,
            }

            lambda_client.invoke(
                FunctionName=process_fn,
                InvocationType="Event",
                Payload=json.dumps(payload),
            )
            print(f"Lambda de procesamiento invocada: {process_fn}")

        # 3) Image uploaded -> guarda observación en DynamoDB
        elif topic_type == "image-uploaded":
            print(f"Imagen subida recibida: {device_id}")

            s3_key = message.get("s3Key") or message.get("imageS3Key")
            if not s3_key:
                return {"statusCode": 400, "body": "Missing s3Key"}

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

        # 4) Status
        elif topic_type == "status":
            print(f"Actualizando estado: {device_id}")
            update_device_status(device_id, message)

        # 5) Sensor data
        elif topic_type == "data":
            print(f"Datos de sensores: {device_id}")
            save_sensor_data(device_id, message)

        else:
            print(f"Topic no manejado: {topic}")

        return {"statusCode": 200, "body": json.dumps({"message": "Processed"})}

    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}


def update_device_status(device_id, message):
    """Actualiza el estado del dispositivo en DynamoDB."""
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
    """Guarda datos de sensores adicionales (placeholder)."""
    print(f"💾 Guardando datos de sensores para {device_id}: {json.dumps(message)}")