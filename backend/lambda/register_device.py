import json
import boto3
import uuid
from datetime import datetime
import os

iot_client = boto3.client('iot')
dynamodb = boto3.resource('dynamodb')
devices_table = dynamodb.Table(os.environ['DEVICES_TABLE'])

def lambda_handler(event, context):
    """
    Registra un nuevo dispositivo ESP32 en AWS IoT Core
    """
    try:
        # Parsear body
        body = json.loads(event.get('body', '{}'))
        device_id = body.get('deviceId')
        user_id = body.get('userId')
        device_name = body.get('deviceName', f'Orion\'s Eye {device_id[:8]}')
        
        if not device_id or not user_id:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': 'deviceId y userId requeridos'})
            }
        
        print(f"Registrando dispositivo: {device_id}")
        
        # 1. Crear Thing en IoT Core
        try:
            iot_client.create_thing(
                thingName=device_id,
                attributePayload={
                    'attributes': {
                        'deviceName': device_name,
                        'userId': user_id,
                        'deviceType': 'ESP32-CAM',
                        'firmware': '1.0.0'
                    }
                }
            )
            print(f"Thing creado: {device_id}")
        except iot_client.exceptions.ResourceAlreadyExistsException:
            print(f"Thing ya existe: {device_id}")
        
        # 2. Crear certificado y claves
        cert_response = iot_client.create_keys_and_certificate(
            setAsActive=True
        )
        
        certificate_arn = cert_response['certificateArn']
        certificate_pem = cert_response['certificatePem']
        private_key = cert_response['keyPair']['PrivateKey']
        public_key = cert_response['keyPair']['PublicKey']
        
        print(f"Certificado creado: {certificate_arn}")
        
        # 3. Adjuntar certificado al Thing
        iot_client.attach_thing_principal(
            thingName=device_id,
            principal=certificate_arn
        )
        
        # 4. Adjuntar política al certificado
        policy_name = os.environ.get('IOT_POLICY_NAME', 'OrionsEyeDevicePolicy')
        
        try:
            iot_client.attach_policy(
                policyName=policy_name,
                target=certificate_arn
            )
            print(f"Política adjuntada: {policy_name}")
        except Exception as e:
            print(f"Error adjuntando política: {e}")
        
        # 5. Guardar en DynamoDB
        timestamp = datetime.utcnow().isoformat()
        
        device_item = {
            'deviceId': device_id,
            'userId': user_id,
            'name': device_name,
            'status': 'online',
            'isOnline': True,
            'certificateArn': certificate_arn,
            'model': 'ESP32-CAM',
            'firmware': '1.0.0',
            'createdAt': timestamp,
            'lastUpdate': timestamp,
            'observations': []
        }
        
        devices_table.put_item(Item=device_item)
        print(f"Dispositivo guardado en DynamoDB")
        
        # 6. Retornar certificados (SOLO ESTA VEZ)
        return {
            'statusCode': 201,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': True,
                'message': 'Dispositivo registrado exitosamente',
                'device': {
                    'deviceId': device_id,
                    'name': device_name,
                    'status': 'online'
                },
                'certificates': {
                    'certificatePem': certificate_pem,
                    'privateKey': private_key,
                    'publicKey': public_key,
                    'certificateArn': certificate_arn
                },
                'iotEndpoint': iot_client.describe_endpoint(endpointType='iot:Data-ATS')['endpointAddress']
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()
        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': str(e)})
        }