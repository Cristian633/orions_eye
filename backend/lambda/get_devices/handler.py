import json
import boto3
import os
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
devices_table = dynamodb.Table(os.environ['DEVICES_TABLE'])

def lambda_handler(event, context):
    """
    GET /devices
    Obtiene todos los dispositivos del usuario autenticado
    """
    try:
        # Obtener userId del token Cognito
        user_id = event['requestContext']['authorizer']['claims']['sub']
        
        print(f"Obteniendo dispositivos para usuario: {user_id}")
        
        # Query por userId usando GSI
        response = devices_table.query(
            IndexName='UserIdIndex',
            KeyConditionExpression='userId = :userId',
            ExpressionAttributeValues={
                ':userId': user_id
            }
        )
        
        devices = response.get('Items', [])
        
        # Convertir Decimals a float para JSON
        devices = json.loads(json.dumps(devices, default=decimal_default))
        
        print(f"Encontrados {len(devices)} dispositivos")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'devices': devices,
                'count': len(devices)
            })
        }
        
    except KeyError:
        # Si no hay token Cognito (para testing)
        print("No hay token Cognito, devolviendo datos de prueba")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'devices': [],
                'count': 0,
                'message': 'Sin autenticación - usa Cognito token'
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