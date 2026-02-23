import json
import boto3
from datetime import datetime

lambda_client = boto3.client('lambda')
dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    """
    Maneja mensajes MQTT del ESP32 vía IoT Rules
    Topics:
      - orionseye/{deviceId}/image
      - orionseye/{deviceId}/status
      - orionseye/{deviceId}/data
    """
    try:
        print(f"Mensaje IoT recibido: {json.dumps(event)}")
        
        # Extraer deviceId del topic
        topic = event.get('topic', '')
        message = event
        
        # Topic format: orionseye/{deviceId}/image
        parts = topic.split('/')
        device_id = parts[1] if len(parts) > 1 else None
        topic_type = parts[2] if len(parts) > 2 else None
        
        if not device_id:
            print("No se pudo extraer deviceId del topic")
            return {'statusCode': 400, 'body': 'Invalid topic'}
        
        # Determinar tipo de mensaje
        if topic_type == 'image':
            # Procesar imagen espectral
            print(f"Procesando imagen del dispositivo: {device_id}")
            
            response = lambda_client.invoke(
                FunctionName='orions-eye-process-image-dev',
                InvocationType='Event',  # Asíncrono
                Payload=json.dumps({
                    'deviceId': device_id,
                    'imageData': message.get('imageData'),
                    'imageS3Key': message.get('imageS3Key'),
                    'userId': message.get('userId'),
                    'timestamp': message.get('timestamp', datetime.utcnow().isoformat())
                })
            )
            
            print(f"Lambda de procesamiento invocada")
            
        elif topic_type == 'status':
            # Actualizar estado del dispositivo
            print(f"Actualizando estado: {device_id}")
            update_device_status(device_id, message)
            
        elif topic_type == 'data':
            # Guardar datos de sensores
            print(f"Datos de sensores: {device_id}")
            save_sensor_data(device_id, message)
        
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Processed successfully'})
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()
        
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def update_device_status(device_id, message):
    """Actualiza el estado del dispositivo en DynamoDB"""
    import os
    devices_table = dynamodb.Table(os.environ['DEVICES_TABLE'])
    
    try:
        devices_table.update_item(
            Key={'deviceId': device_id},
            UpdateExpression='SET #status = :status, lastUpdate = :timestamp, isOnline = :online',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':status': message.get('status', 'online'),
                ':timestamp': datetime.utcnow().isoformat(),
                ':online': True
            }
        )
        print(f"Estado actualizado para {device_id}")
    except Exception as e:
        print(f"Error actualizando estado: {e}")

def save_sensor_data(device_id, message):
    """Guarda datos de sensores adicionales"""
    print(f"💾 Guardando datos de sensores: {message}")
    # TODO: Implementar si el ESP32 tiene sensores adicionales (temperatura, etc)