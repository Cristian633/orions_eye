import json
import boto3
import os
from decimal import Decimal

dynamodb = boto3.resource("dynamodb")
observations_table = dynamodb.Table(os.environ["OBSERVATIONS_TABLE"])

S3_BUCKET = os.environ["S3_BUCKET"]
AWS_REGION = os.environ.get("AWS_REGION", "us-east-2")


def lambda_handler(event, context):
    """
    GET /observations?deviceId={deviceId}&limit={limit}
    Obtiene observaciones del usuario o dispositivo específico
    """
    try:
        user_id = event["requestContext"]["authorizer"]["claims"]["sub"]

        params = event.get("queryStringParameters") or {}
        device_id = params.get("deviceId")
        limit = min(int(params.get("limit", 50)), 200)

        print(f"Obteniendo observaciones para usuario: {user_id}")

        if device_id:
            print(f"Filtrando por deviceId: {device_id}")
            response = observations_table.query(
                IndexName="DeviceIdIndex",
                KeyConditionExpression="deviceId = :deviceId",
                ExpressionAttributeValues={":deviceId": device_id},
                Limit=limit,
                ScanIndexForward=False,
            )
            items = response.get("Items", [])
            # Seguridad: filtra sólo items del user logueado
            items = [it for it in items if it.get("userId") == user_id]
        else:
            response = observations_table.query(
                IndexName="UserIdIndex",
                KeyConditionExpression="userId = :userId",
                ExpressionAttributeValues={":userId": user_id},
                Limit=limit,
                ScanIndexForward=False,
            )
            items = response.get("Items", [])

        observations = json.loads(json.dumps(items, default=decimal_default))

        # Normalizar imageUrl para app
        for obs in observations:
            key = obs.get("imageS3Key") or obs.get("s3Key")
            url = obs.get("imageUrl")

            # Si imageUrl está vacía o es path relativo, construir URL pública regional
            if (not url or not str(url).startswith("http")) and key:
                obs["imageUrl"] = f"https://{S3_BUCKET}.s3.{AWS_REGION}.amazonaws.com/{key}"

            # Si url vieja usa s3.amazonaws.com, forzar regional
            elif url and f"{S3_BUCKET}.s3.amazonaws.com/" in url:
                obs["imageUrl"] = url.replace(
                    f"{S3_BUCKET}.s3.amazonaws.com/",
                    f"{S3_BUCKET}.s3.{AWS_REGION}.amazonaws.com/",
                )

        print(f"Encontradas {len(observations)} observaciones")

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps({"observations": observations, "count": len(observations)}),
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()

        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
            },
            "body": json.dumps({"error": str(e)}),
        }


def decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError