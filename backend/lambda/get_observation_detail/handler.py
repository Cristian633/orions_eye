import json
import boto3
import os
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
observations_table = dynamodb.Table(os.environ['OBSERVATIONS_TABLE'])

def lambda_handler(event, context):
    user_id = event['requestContext']['authorizer']['claims']['sub']
    observation_id = event['pathParameters']['observationId']

    resp = observations_table.get_item(Key={'observationId': observation_id})
    item = resp.get('Item')

    if not item:
        return _resp(404, {'error': 'Observación no encontrada'})

    if item.get('userId') != user_id:
        return _resp(403, {'error': 'No autorizado'})

    item = json.loads(json.dumps(item, default=_decimal))
    return _resp(200, {'observation': item})

def _decimal(o):
    if isinstance(o, Decimal):
        return float(o)
    raise TypeError

def _resp(code, body):
    return {
        'statusCode': code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body)
    }