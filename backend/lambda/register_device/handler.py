import json
import boto3
import os
from datetime import datetime
import re


iot_client = boto3.client("iot")
dynamodb = boto3.resource("dynamodb")
devices_table = dynamodb.Table(os.environ["DEVICES_TABLE"])


def _parse_body(event):
    body = event.get("body")
    if body is None:
        return {}
    if isinstance(body, dict):
        return body
    if isinstance(body, str):
        # intenta 1 vez (JSON normal) y 2 veces (doble serializado)
        try:
            parsed = json.loads(body)
            if isinstance(parsed, str):
                return json.loads(parsed)
            if isinstance(parsed, dict):
                return parsed
        except json.JSONDecodeError:
            return {}
    return {}


def lambda_handler(event, context):
    try:
        # DEBUG: ver qué llega realmente desde API Gateway
        print("=== register_device DEBUG ===")
        print("event keys:", list(event.keys()))
        print("raw body type:", type(event.get("body")).__name__)
        print("raw body:", event.get("body"))
        print("headers:", event.get("headers"))

        user_id = event["requestContext"]["authorizer"]["claims"]["sub"]

        body = _parse_body(event)
        print("parsed body:", body)

        device_id = body.get("deviceId")
        if not device_id:
            return response(400, {"error": "deviceId es requerido"})

        raw_name = body.get("deviceName") or f"OrionsEye-{device_id[:8]}"
        device_name = re.sub(r"[^a-zA-Z0-9_.,/@#:\\-]", "_", raw_name)  # Limpia el nombre para IoT

        attributes = {
            "deviceName": device_name,
            "userId": str(user_id),
            "deviceType": "ESP32-CAM"
}


        # 1) Crear Thing (sin atributos)
        try:
            iot_client.create_thing(thingName=device_id)
            print(f"Thing creado: {device_id}")
        except iot_client.exceptions.ResourceAlreadyExistsException:
            print(f"Thing ya existe: {device_id}")

        # 1b) Actualizar atributos del Thing (merge=True)
        iot_client.update_thing(
            thingName=device_id,
            attributePayload={
                "attributes": attributes,
                "merge": True,
            },
        )
        print("Thing attributes updated")

        # 2. Crear certificado y claves
        cert_response = iot_client.create_keys_and_certificate(setAsActive=True)

        certificate_arn = cert_response["certificateArn"]
        certificate_pem = cert_response["certificatePem"]
        private_key = cert_response["keyPair"]["PrivateKey"]
        public_key = cert_response["keyPair"]["PublicKey"]

        print(f"Certificado creado: {certificate_arn}")

        # 3. Adjuntar certificado al Thing
        iot_client.attach_thing_principal(thingName=device_id, principal=certificate_arn)

        # 4. Adjuntar política al certificado
        policy_name = os.environ.get("IOT_POLICY_NAME", "OrionsEyeDevicePolicy")

        try:
            iot_client.attach_policy(policyName=policy_name, target=certificate_arn)
            print(f"Política adjuntada: {policy_name}")
        except Exception as e:
            print(f"Error adjuntando política: {e}")

        # 5. Guardar en DynamoDB
        timestamp = datetime.utcnow().isoformat()

        device_item = {
            "deviceId": device_id,
            "userId": user_id,
            "name": device_name,
            "status": "online",
            "isOnline": True,
            "certificateArn": certificate_arn,
            "model": "ESP32-CAM",
            "firmware": "1.0.0",
            "createdAt": timestamp,
            "lastUpdate": timestamp,
        }

        devices_table.put_item(Item=device_item)
        print("Dispositivo guardado en DynamoDB")

        # 6. Obtener IoT Endpoint
        iot_endpoint = iot_client.describe_endpoint(endpointType="iot:Data-ATS")[
            "endpointAddress"
        ]

        # 7. Retornar certificados (SOLO ESTA VEZ)
        return response(
            201,
            {
                "success": True,
                "message": "Dispositivo registrado exitosamente",
                "device": {
                    "deviceId": device_id,
                    "name": device_name,
                    "status": "online",
                },
                "certificates": {
                    "certificatePem": certificate_pem,
                    "privateKey": private_key,
                    "publicKey": public_key,
                    "certificateArn": certificate_arn,
                },
                "iotEndpoint": iot_endpoint,
            },
        )

    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback

        traceback.print_exc()
        return response(500, {"error": str(e)})


def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,Authorization",
            "Access-Control-Allow-Methods": "OPTIONS,GET,POST,PUT,DELETE",
        },
        "body": json.dumps(body),
    }