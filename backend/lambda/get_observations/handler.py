import json
import boto3
import os
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
observations_table = dynamodb.Table(os.environ['OBSERVATIONS_TABLE'])

def lambda_handler(event, context):
    """
    GET /observations?deviceId={deviceId}&limit={limit}
    Obtiene observaciones del usuario o dispositivo específico
    """
    try:
        # Obtener userId del token Cognito
        user_id = event['requestContext']['authorizer']['claims']['sub']
        
        # Parámetros de query
        params = event.get('queryStringParameters') or {}
        device_id = params.get('deviceId')
        limit = int(params.get('limit', 50))
        
        print(f"Obteniendo observaciones para usuario: {user_id}")
        
        if device_id:
            # Query por deviceId (debe pertenecer al usuario)
            print(f"🔍 Filtrando por deviceId: {device_id}")
            
            # Primero verificar que el dispositivo pertenece al usuario
            # (en producción deberías hacer esta validación)
            
            response = observations_table.query(
                IndexName='DeviceIdIndex',
                KeyConditionExpression='deviceId = :deviceId',
                ExpressionAttributeValues={
                    ':deviceId': device_id
                },
                Limit=limit,
                ScanIndexForward=False  # Orden descendente (más recientes primero)
            )
        else:
            # Query por userId - todas las observaciones del usuario
            response = observations_table.query(
                IndexName='UserIdIndex',
                KeyConditionExpression='userId = :userId',
                ExpressionAttributeValues={
                    ':userId': user_id
                },
                Limit=limit,
                ScanIndexForward=False
            )
        
        observations = response.get('Items', [])
        
        # Convertir Decimals a float para JSON
        observations = json.loads(json.dumps(observations, default=decimal_default))
        
        print(f"Encontradas {len(observations)} observaciones")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'observations': observations,
                'count': len(observations)
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()
        
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError