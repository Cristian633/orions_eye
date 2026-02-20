Despliegue manual de la Lambda `get_devices`

1) Contenido de la carpeta
- `handler.py` : handler de la función.
- `requirements.txt` : lista de dependencias (actualmente vacía porque `boto3` está incluido en el runtime de Lambda).

2) Empaquetar (desde la raíz del repo en Windows PowerShell):

```powershell
cd backend\lambda\get_devices
Compress-Archive -Path * -DestinationPath ..\get_devices.zip -Force
```

Esto creará `backend\lambda\get_devices.zip` con el código listo.

3) Subir por consola AWS Lambda
- Abrir la consola Lambda → seleccionar la función (o crearla con el mismo nombre en `template.yaml`).
- En "Code" → "Upload from" seleccionar ".zip file" y subir `backend/get_devices.zip` (ruta relativa: `backend\get_devices.zip`).
- Ajustar Handler a `handler.lambda_handler` si no está puesto.

4) Subir con AWS CLI (si tienes credenciales configuradas):

```bash
aws lambda update-function-code --function-name orions-eye-get-devices-dev --zip-file fileb://backend/lambda/get_devices.zip
```

Cambia `--function-name` por el nombre real de la función si es distinto.

5) Notas
- Si necesitas que despliegue yo vía AWS CLI, dame permiso para usar tus credenciales o configúralas localmente (`aws configure`).
- Si más funciones tienen dependencias, instala paquetes con `python -m pip install -r requirements.txt -t .` dentro de la carpeta antes de crear el ZIP.
