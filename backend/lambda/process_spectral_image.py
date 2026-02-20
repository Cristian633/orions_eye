import json
import boto3
import base64
import os
from datetime import datetime
from decimal import Decimal
import numpy as np
from PIL import Image
import io

s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
observations_table = dynamodb.Table(os.environ['OBSERVATIONS_TABLE'])
devices_table = dynamodb.Table(os.environ['DEVICES_TABLE'])

S3_BUCKET = os.environ['S3_BUCKET']

def lambda_handler(event, context):
    """
    Procesa imágenes espectrales del ESP32
    1. Recibe imagen en base64 o desde S3
    2. Analiza el espectro
    3. Guarda metadata en DynamoDB
    4. Retorna datos procesados
    """
    try:
        print("📸 Procesando imagen espectral...")
        
        # Obtener datos del evento IoT Core
        device_id = event.get('deviceId')
        user_id = event.get('userId')
        
        # Imagen puede venir en base64 o referencia S3
        image_data = event.get('imageData')
        image_s3_key = event.get('imageS3Key')
        
        if not device_id:
            raise ValueError("deviceId es requerido")
        
        # 1. Obtener la imagen
        if image_s3_key:
            # Descargar desde S3
            response = s3_client.get_object(Bucket=S3_BUCKET, Key=image_s3_key)
            image_bytes = response['Body'].read()
        elif image_data:
            # Decodificar base64
            image_bytes = base64.b64decode(image_data)
        else:
            raise ValueError("Se requiere imageData o imageS3Key")
        
        # 2. Procesar la imagen
        image = Image.open(io.BytesIO(image_bytes))
        
        print(f"📏 Imagen: {image.size[0]}x{image.size[1]}, mode: {image.mode}")
        
        # 3. Analizar espectro
        spectral_data = analyze_spectrum(image)
        
        # 4. Guardar imagen en S3 si no estaba
        if not image_s3_key:
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
            print(f"✅ Imagen guardada en S3: {image_s3_key}")
        
        # 5. Crear observación en DynamoDB
        observation_id = f"obs_{device_id}_{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"
        timestamp = datetime.utcnow().isoformat()
        
        observation = {
            'observationId': observation_id,
            'deviceId': device_id,
            'userId': user_id or 'unknown',
            'timestamp': timestamp,
            'imageUrl': f"https://{S3_BUCKET}.s3.amazonaws.com/{image_s3_key}",
            'imageS3Key': image_s3_key,
            'spectralData': spectral_data,
            'status': 'processed',
            'createdAt': timestamp
        }
        
        observations_table.put_item(Item=convert_floats_to_decimals(observation))
        print(f"Observación guardada: {observation_id}")
        
        # 6. Actualizar dispositivo
        devices_table.update_item(
            Key={'deviceId': device_id},
            UpdateExpression='SET lastUpdate = :timestamp, lastObservation = :obsId',
            ExpressionAttributeValues={
                ':timestamp': timestamp,
                ':obsId': observation_id
            }
        )
        
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


def analyze_spectrum(image):
    """
    Analiza la imagen espectral y extrae datos
    """
    try:
        # Convertir a array numpy
        img_array = np.array(image)
        
        # Si es RGB, convertir a escala de grises
        if len(img_array.shape) == 3:
            img_gray = np.mean(img_array, axis=2)
        else:
            img_gray = img_array
        
        # Extraer perfil horizontal (promedio vertical)
        spectrum_profile = np.mean(img_gray, axis=0)
        
        # Normalizar entre 0-100
        spectrum_normalized = ((spectrum_profile - spectrum_profile.min()) / 
                               (spectrum_profile.max() - spectrum_profile.min()) * 100)
        
        # Detectar picos
        peaks = detect_peaks(spectrum_normalized)
        
        # Calcular longitudes de onda aproximadas (calibración necesaria)
        # Asumiendo espectro visible 400-700nm
        wavelengths = np.linspace(400, 700, len(spectrum_normalized))
        
        # Identificar líneas espectrales prominentes
        spectral_lines = []
        for peak_idx in peaks:
            wavelength = float(wavelengths[peak_idx])
            intensity = float(spectrum_normalized[peak_idx])
            
            # Identificar elemento (simplificado)
            element = identify_element(wavelength)
            
            spectral_lines.append({
                'wavelength': round(wavelength, 2),
                'intensity': round(intensity, 2),
                'element': element
            })
        
        return {
            'spectralProfile': spectrum_normalized.tolist(),
            'wavelengths': wavelengths.tolist(),
            'spectralLines': spectral_lines,
            'peakCount': len(peaks),
            'averageIntensity': float(np.mean(spectrum_normalized)),
            'maxIntensity': float(np.max(spectrum_normalized)),
            'imageSize': list(image.size)
        }
        
    except Exception as e:
        print(f"Error en análisis: {e}")
        return {
            'error': str(e),
            'spectralProfile': [],
            'spectralLines': []
        }


def detect_peaks(data, threshold=70):
    """
    Detecta picos en el perfil espectral
    """
    peaks = []
    for i in range(1, len(data) - 1):
        if data[i] > threshold and data[i] > data[i-1] and data[i] > data[i+1]:
            peaks.append(i)
    return peaks


def identify_element(wavelength):
    """
    Identifica posibles elementos basándose en longitud de onda
    (Simplificado - necesita calibración real)
    """
    # Líneas espectrales conocidas (nm)
    spectral_lines = {
        'H-alpha': 656.3,    # Hidrógeno
        'H-beta': 486.1,     # Hidrógeno
        'He': 587.6,         # Helio
        'Na-D': 589.0,       # Sodio
        'O': 630.0,          # Oxígeno
        'Fe': 532.8,         # Hierro
        'Ca': 422.7,         # Calcio
    }
    
    # Buscar coincidencia (tolerancia ±5nm)
    tolerance = 5
    for element, line_wavelength in spectral_lines.items():
        if abs(wavelength - line_wavelength) < tolerance:
            return element
    
    return 'Unknown'


def convert_floats_to_decimals(obj):
    """
    Convierte floats a Decimals para DynamoDB
    """
    if isinstance(obj, list):
        return [convert_floats_to_decimals(item) for item in obj]
    elif isinstance(obj, dict):
        return {key: convert_floats_to_decimals(value) for key, value in obj.items()}
    elif isinstance(obj, float):
        return Decimal(str(obj))
    else:
        return obj