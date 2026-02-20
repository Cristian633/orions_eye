Write-Host "╔═══════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ORION'S EYE - FIRST DEPLOYMENT     ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# Verificar AWS CLI
Write-Host "Verificando AWS CLI..." -ForegroundColor Yellow
$identity = aws sts get-caller-identity 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "AWS CLI no configurado" -ForegroundColor Red
    Write-Host "Ejecuta: aws configure"
    exit 1
}

Write-Host "AWS CLI configurado" -ForegroundColor Green
Write-Host ""

# Build
Write-Host "🏗️  Building..." -ForegroundColor Yellow
sam build

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed" -ForegroundColor Red
    exit 1
}

Write-Host "Build OK" -ForegroundColor Green
Write-Host ""

# Deploy
Write-Host "Deploying..." -ForegroundColor Yellow
sam deploy --guided

Write-Host ""
Write-Host "Deployment completado!" -ForegroundColor Green