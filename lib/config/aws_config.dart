class AwsConfig {
  // COGNITO - Autenticación
  static const String userPoolId = 'us-east-2_I6UCDeRO3';
  static const String clientId = '6irncagskoghm3h02mie6bin0v';
  static const String region = 'us-east-2';

   // DYNAMODB - Base de datos (próximamente)
   static const String devicesTableName = 'orions-eye-devices';
   static const String observationsTableName = 'orions-eye-observations';

   // S3 - Almacenamiento de imágenes (próximamente)
   static const String s3BucketName = 'orions-eye-observations';
   static const String s3Region = 'us-east-2';

   // API GATEWAY - APIs REST 
   static const String apiEndpoint = 'https://wovrlgy45g.execute-api.us-east-2.amazonaws.com/Prod';

   // IOT CORE - Comunicación con ESP32 (próximamente)
   static const String iotEndpoint = '';
}