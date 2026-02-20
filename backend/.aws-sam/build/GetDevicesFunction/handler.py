import json

def lambda_handler(event, context):
    """
    Lambda de prueba - GET /devices
    """
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'message': '🎉 Backend funcionando!',
            'devices': [
                {
                    'deviceId': 'test-device-001',
                    'name': 'Test Device',
                    'status': 'online'
                }
            ]
        })
    }