class AwsConfig {
  // COGNITO - Autenticación
  static const String userPoolId = 'us-east-2_I6UCDeRO3';
  static const String clientId = '6irncagskoghm3h02mie6bin0v';
  static const String region = 'us-east-2';

  // API GATEWAY - APIs REST
  static const String apiEndpoint =
      'https://wovrlgy45g.execute-api.us-east-2.amazonaws.com/Prod';

  // Estos nombres son informativos (la app normalmente NO los usa directo)
  // Los saco de tus Outputs del stack orions-eye-backend-dev:
  static const String devicesTableName = 'orions-eye-devices-dev';
  static const String observationsTableName = 'orions-eye-observations-dev';
  static const String s3BucketName = 'orions-eye-images-dev-219282777127';
  static const String s3Region = 'us-east-2';

  // IoT Core (para el ESP32). Mejor usar Data-ATS.
  // Por ahora te dejo el de CloudFormation:
  static const String iotEndpoint = '219282777127.iot.us-east-2.amazonaws.com';
}