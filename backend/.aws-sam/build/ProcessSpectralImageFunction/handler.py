import json
import boto3
import base64
import os
from datetime import datetime
from decimal import Decimal
import io

s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
observations_table = dynamodb.Table(os.environ['OBSERVATIONS_TABLE'])
devices_table = dynamodb.Table(os.environ['DEVICES_TABLE'])

S3_BUCKET = os.environ['S3_BUCKET']

def lambda_handler(event, context):
    """
    Procesa imágenes espectrales del ESP32
    Recibe: imagen en base64 o referencia S3
    Output: Análisis guardado en DynamoDB
    """
    try:
        print("📸 Procesando imagen espectral...")
        
        # Obtener datos del evento
        device_id = event.get('deviceId')
        user_id = event.get('userId', 'unknown')
        
        # Imagen puede venir en base64 o referencia S3
        image_data = event.get('imageData')
        image_s3_key = event.get('imageS3Key')
        
        if not device_id:
            raise ValueError("deviceId es requerido")
        
        # 1. Obtener la imagen
        if image_s3_key:
            # Ya está en S3
            print(f"Imagen ya en S3: {image_s3_key}")
        elif image_data:
            # Decodificar base64 y subir a S3
            image_bytes = base64.b64decode(image_data)
            
            timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
            image_s3_key = f"observations/{device_id}/{timestamp}_spectrum.jpg"
            
            s3_client.put_object(
                Bucket=S3_BUCKET,
                Key=image_s3_key,
                Body=image_bytes,
                ContentType='image/jpeg',
                Metadata={
                    'deviceId': device_id,
                    'timestamp': timestamp,
                    'type': 'spectral_image'
                }
            )
            print(f"Imagen subida a S3: {image_s3_key}")
        else:
            raise ValueError("Se requiere imageData o imageS3Key")
        
        # 2. Análisis espectral (simplificado por ahora)
        spectral_data = analyze_spectrum_simple()
        
        # 3. Crear observación en DynamoDB
        observation_id = f"obs_{device_id}_{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"
        timestamp = datetime.utcnow().isoformat()
        
        observation = {
            'observationId': observation_id,
            'deviceId': device_id,
            'userId': user_id,
            'timestamp': timestamp,
            'imageUrl': f"https://{S3_BUCKET}.s3.amazonaws.com/{image_s3_key}",
            'imageS3Key': image_s3_key,
            'spectralData': spectral_data,
            'status': 'processed',
            'createdAt': timestamp
        }
        
        observations_table.put_item(Item=convert_floats_to_decimals(observation))
        print(f"Observación guardada: {observation_id}")
        
        # 4. Actualizar dispositivo
        try:
            devices_table.update_item(
                Key={'deviceId': device_id},
                UpdateExpression='SET lastUpdate = :timestamp, lastObservation = :obsId',
                ExpressionAttributeValues={
                    ':timestamp': timestamp,
                    ':obsId': observation_id
                }
            )
        except Exception as e:
            print(f"No se pudo actualizar dispositivo: {e}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'success': True,
                'observationId': observation_id,
                'imageUrl': observation['imageUrl'],
                'spectralData': spectral_data
            })
        }
        
    except Exception as e:
        print(f"Error procesando imagen: {str(e)}")
        import traceback
        traceback.print_exc()
        
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def analyze_spectrum_simple():
    """
    Análisis espectral simplificado
    TODO: Implementar análisis real con PIL/OpenCV cuando tengamos imágenes reales
    """
    return {
        'wavelengths': list(range(400, 701, 10)),  # 400-700nm (espectro visible)
        'intensities': [50 + (i % 30) for i in range(31)],  # Datos de ejemplo
        'peaks': [
            {'wavelength': 486, 'intensity': 85, 'element': 'H-beta'},
            {'wavelength': 589, 'intensity': 92, 'element': 'Na-D'},
            {'wavelength': 656, 'intensity': 78, 'element': 'H-alpha'}
        ],
        'averageIntensity': 65.5,
        'maxIntensity': 92.0,
        'quality': 'good'
    }

def convert_floats_to_decimals(obj):
    """Convierte floats a Decimals para DynamoDB"""
    if isinstance(obj, list):
        return [convert_floats_to_decimals(item) for item in obj]
    elif isinstance(obj, dict):
        return {key: convert_floats_to_decimals(value) for key, value in obj.items()}
    elif isinstance(obj, float):
        return Decimal(str(obj))
    else:
        return obj