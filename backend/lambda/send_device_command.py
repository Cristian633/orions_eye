import json
import boto3
import os

iot_data_client = boto3.client('iot-data')

def lambda_handler(event, context):
    """
    Envía comandos al ESP32 vía MQTT
    Endpoint: POST /devices/{deviceId}/command
    """
    try:
        # Obtener deviceId del path
        device_id = event['pathParameters']['deviceId']
        
        # Parsear body
        body = json.loads(event.get('body', '{}'))
        command = body.get('command')
        payload = body.get('payload', {})
        
        if not command:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': 'command es requerido'})
            }
        
        print(f"Enviando comando '{command}' a {device_id}")
        
        # Topic MQTT: orionseye/{deviceId}/command
        topic = f"orionseye/{device_id}/command"
        
        # Mensaje MQTT
        message = {
            'command': command,
            'payload': payload,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        # Publicar en IoT Core
        iot_data_client.publish(
            topic=topic,
            qos=1,
            payload=json.dumps(message)
        )
        
        print(f"Comando enviado a topic: {topic}")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': True,
                'message': f'Comando "{command}" enviado',
                'deviceId': device_id
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': str(e)})
        }