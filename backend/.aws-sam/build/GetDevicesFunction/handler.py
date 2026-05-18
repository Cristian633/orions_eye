import json
import os
import boto3
from boto3.dynamodb.conditions import Attr

dynamodb = boto3.resource("dynamodb")
TABLE_NAME = os.environ.get("DEVICES_TABLE")

def resp(status, body):
    return {
        "statusCode": status,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,Authorization",
            "Access-Control-Allow-Methods": "OPTIONS,GET"
        },
        "body": json.dumps(body)
    }

def lambda_handler(event, context):
    try:
        method = event.get("httpMethod") or event.get("requestContext", {}).get("http", {}).get("method")
        if method == "OPTIONS":
            return resp(200, {"ok": True})

        if not TABLE_NAME:
            return resp(500, {"error": "DEVICES_TABLE missing"})

        claims = (
            event.get("requestContext", {})
            .get("authorizer", {})
            .get("jwt", {})
            .get("claims")
            or event.get("requestContext", {}).get("authorizer", {}).get("claims")
            or {}
        )

        user_id = claims.get("sub") or claims.get("username")
        if not user_id:
            return resp(401, {"error": "Unauthorized: missing user in token"})

        table = dynamodb.Table(TABLE_NAME)

        # Tu tabla usa PK deviceId, por eso scan + filtro por userId
        result = table.scan(
            FilterExpression=Attr("userId").eq(user_id)
        )
        items = result.get("Items", [])

        devices = []
        for it in items:
            devices.append({
                "id": it.get("deviceId", ""),
                "name": it.get("deviceName", "OrionSpectrometer"),
                "isOnline": it.get("status") == "online",
                "status": it.get("status", "registered"),
                "lastUpdate": it.get("updatedAt") or it.get("createdAt"),
                "userId": it.get("userId", user_id),
                "position": it.get("position")
            })

        return resp(200, {"devices": devices})
    except Exception as e:
        print("getDevices error:", str(e))
        return resp(500, {"error": "Internal server error", "detail": str(e)})