Write-Host "╔═══════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ORION'S EYE - FULL BACKEND DEPLOY  ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# Verificar estructura
Write-Host " Verificando estructura..." -ForegroundColor Yellow
$folders = @(
    "lambda/get_devices",
    "lambda/register_device",
    "lambda/send_device_command",
    "lambda/get_observations",
    "lambda/get_observation_detail",
    "lambda/process_spectral_image",
    "lambda/iot_rule_handler"
)

foreach ($folder in $folders) {
    if (!(Test-Path $folder)) {
        Write-Host " Falta carpeta: $folder" -ForegroundColor Red
        exit 1
    }
}

Write-Host " Estructura correcta" -ForegroundColor Green
Write-Host ""

# Build
Write-Host "  Building..." -ForegroundColor Yellow
sam build

if ($LASTEXITCODE -ne 0) {
    Write-Host " Build failed" -ForegroundColor Red
    exit 1
}

Write-Host " Build OK" -ForegroundColor Green
Write-Host ""

# Deploy
Write-Host "🚀 Deploying..." -ForegroundColor Yellow
sam deploy

if ($LASTEXITCODE -ne 0) {
    Write-Host "Deploy failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "╔═══════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              DEPLOY EXITOSO!          ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# Mostrar outputs
Write-Host "Stack Outputs:" -ForegroundColor Yellow
aws cloudformation describe-stacks `
    --stack-name "orions-eye-backend-dev" `
    --region us-east-2 `
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' `
    --output table

Write-Host ""
Write-Host "Backend desplegado con:" -ForegroundColor Green
Write-Host "   - 7 Lambda Functions" -ForegroundColor White
Write-Host "   - 2 DynamoDB Tables" -ForegroundColor White
Write-Host "   - 1 S3 Bucket" -ForegroundColor White
Write-Host "   - API Gateway con Cognito Auth" -ForegroundColor White
Write-Host "   - IoT Core (Policy + Rules)" -ForegroundColor White