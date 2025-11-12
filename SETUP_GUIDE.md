# Setup Guide - Mindful Moments Infrastructure

Guía paso a paso para desplegar la infraestructura de Azure.

## 📋 Prerequisitos

### 1. Herramientas Necesarias

```bash
# Verificar Azure CLI
az --version

# Verificar Terraform
terraform version  # Requiere >= 1.7.0

# Verificar Git
git --version
```

### 2. Autenticación Azure

```bash
# Login a Azure
az login

# Verificar suscripción activa
az account show

# Cambiar suscripción si es necesario
az account set --subscription "353a6255-27a8-4733-adf0-1c531ba9f4e9"
```

## 🚀 Paso 1: Configurar Backend de Terraform

El backend almacena el estado de Terraform de forma remota en Azure Storage.

```bash
cd terraform/scripts

# Ejecutar script de setup
./setup-backend.sh
```

El script creará:
- Resource Group: `rg-terraform-state`
- Storage Account: `sttfstate<random>`
- Blob Container: `tfstate`
- Archivo: `../environments/dev/backend.tfbackend`

**Salida esperada:**
```
================================================== ✅ Setup Complete!
==================================================

Backend configuration:
  Resource Group:   rg-terraform-state
  Storage Account:  sttfstate1a2b3c4d
  Container:        tfstate
  State File:       dev.tfstate
```

## 🔧 Paso 2: Configurar Variables

```bash
cd ../environments/dev

# Copiar archivo de ejemplo
cp terraform.tfvars.example terraform.tfvars

# Editar con tus valores
nano terraform.tfvars  # o vim, code, etc.
```

**Configuración requerida en `terraform.tfvars`:**

```hcl
# PostgreSQL administrator password (OBLIGATORIO)
# Requisitos: Mínimo 8 caracteres, mayúsculas, minúsculas y números
postgres_admin_password = "TuPassword123!"

# Email para alertas de monitoring (OBLIGATORIO)
alert_email = "tu.email@ejemplo.com"

# Opcionales (usa los valores por defecto o sobrescribe)
# environment = "dev"
# location = "westeurope"
# owner = "alberto.lacambra"
```

⚠️ **IMPORTANTE**: 
- El archivo `terraform.tfvars` NO se sube a Git (.gitignore)
- Guarda las credenciales de forma segura (ej: Azure Key Vault, 1Password)

## 🏗️ Paso 3: Inicializar Terraform

```bash
# Opción A: Usar script helper
../../scripts/init-env.sh

# Opción B: Manual
terraform init -backend-config=backend.tfbackend
```

**Salida esperada:**
```
Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure.
```

## ✅ Paso 4: Validar Configuración

```bash
# Validar sintaxis
terraform validate

# Formatear código (opcional)
terraform fmt -recursive

# O usar script de validación
../../scripts/validate.sh
```

## 📊 Paso 5: Planificar Despliegue

```bash
# Generar plan de ejecución
terraform plan -out=tfplan

# Revisar el plan generado
# Terraform mostrará todos los recursos que se crearán
```

**Recursos que se crearán (38 en total):**
- 1 Resource Group
- 1 Virtual Network
- 2 Subnets (app, database)
- 1 Network Security Group
- 1 Private DNS Zone
- 1 App Service Plan (B1)
- 1 Linux Web App
- 1 PostgreSQL Flexible Server (B1ms)
- 1 Database
- 1 Storage Account
- 2 Storage Containers
- 1 Log Analytics Workspace
- 1 Application Insights
- 1 Action Group (alertas)
- 4 Metric Alerts
- 1 Key Vault
- 3 Key Vault Secrets
- Varios access policies y associations

**Estimación de costos:**
```
Coste mensual estimado: ~56-61€
Presupuesto máximo: 120€
Buffer disponible: ~60€
```

## 🚢 Paso 6: Desplegar Infraestructura

```bash
# Aplicar el plan
terraform apply tfplan

# Confirmar cuando se solicite
# El proceso tardará aproximadamente 10-15 minutos
```

**Progreso esperado:**
```
azurerm_resource_group.main: Creating...
azurerm_resource_group.main: Creation complete after 2s
module.networking.azurerm_virtual_network.main: Creating...
...
Apply complete! Resources: 38 added, 0 changed, 0 destroyed.

Outputs:
app_service_url = "https://app-mindful-moments-dev.azurewebsites.net"
database_name = "mindfuldb"
postgres_server_fqdn = "psql-mindful-moments-dev.postgres.database.azure.com"
resource_group_name = "rg-mindful-moments-dev"
storage_account_name = "stmindful1a2b3c"
key_vault_uri = "https://kv-mindful1a2b3c.vault.azure.net/"
```

## 🔍 Paso 7: Verificar Despliegue

### 7.1 Verificar en Azure Portal

```bash
# Abrir en el navegador
az group show --name rg-mindful-moments-dev --query id -o tsv | \
  xargs -I {} echo "https://portal.azure.com/#@/resource/{}/overview"
```

### 7.2 Verificar App Service

```bash
# Obtener URL de la aplicación
APP_URL=$(terraform output -raw app_service_url)
echo "App Service URL: $APP_URL"

# Probar endpoint de salud (404 esperado hasta que se despliegue la app)
curl -I $APP_URL/health
```

### 7.3 Verificar Base de Datos

```bash
# Verificar conexión desde App Service
az webapp ssh --resource-group rg-mindful-moments-dev \
              --name app-mindful-moments-dev
# Dentro del SSH:
# nc -zv <postgres-fqdn> 5432
```

### 7.4 Verificar Storage

```bash
# Listar contenedores
STORAGE_ACCOUNT=$(terraform output -raw storage_account_name)
az storage container list --account-name $STORAGE_ACCOUNT \
                          --auth-mode login \
                          --output table
```

### 7.5 Verificar Key Vault

```bash
# Listar secretos
az keyvault secret list --vault-name $(terraform output -raw key_vault_name | sed 's|.*/||') \
                        --output table
```

### 7.6 Verificar Monitoring

```bash
# Ver métricas de Application Insights (requiere datos)
az monitor app-insights component show \
  --app appi-mindful-moments-dev \
  --resource-group rg-mindful-moments-dev
```

## 📈 Paso 8: Configurar Alertas

Las alertas ya están configuradas, pero verifica:

```bash
# Listar alertas
az monitor metrics alert list \
  --resource-group rg-mindful-moments-dev \
  --output table

# Ver detalles de una alerta
az monitor metrics alert show \
  --name app-cpu-high \
  --resource-group rg-mindful-moments-dev
```

**Alertas configuradas:**
- `app-cpu-high`: CPU > 80% por 5 minutos
- `app-memory-high`: Memoria > 80% por 5 minutos
- `db-cpu-high`: DB CPU > 80% por 5 minutos
- `db-storage-high`: DB Storage > 80% por 15 minutos

## 🔄 Siguientes Pasos

### 1. Desplegar Aplicación

La infraestructura está lista. Próximos pasos:
- Crear aplicación Node.js "Mindful Moments"
- Configurar CI/CD con GitHub Actions
- Desplegar desde repositorio

### 2. Configurar Azure SRE Agent

Ver [docs/sre-agent-setup.md](docs/sre-agent-setup.md) _(próximamente)_

### 3. Configurar Alertas Telefónicas

Ver [docs/phone-alerts.md](docs/phone-alerts.md) _(próximamente)_

### 4. Monitorear Costes

```bash
# Ver costes actuales
az consumption usage list \
  --billing-period-name $(date +%Y%m) \
  --query "[?contains(instanceName,'mindful')].{Name:instanceName,Cost:pretaxCost}" \
  --output table

# O en Azure Portal:
# Cost Management + Billing > Cost Analysis
# Filtrar por: Resource Group = rg-mindful-moments-dev
```

**Límite de alerta recomendado:**
- Alerta al 80%: 96€
- Alerta al 90%: 108€
- Límite máximo: 120€

## 🛠️ Comandos Útiles

### Ver Outputs

```bash
terraform output                      # Todos los outputs
terraform output app_service_url      # Output específico
terraform output -raw database_name   # Sin comillas
```

### Actualizar Infraestructura

```bash
# Editar archivos .tf según necesites
terraform plan -out=tfplan
terraform apply tfplan
```

### Destruir Infraestructura (¡CUIDADO!)

```bash
# Destruir todos los recursos
terraform destroy

# Destruir recursos específicos
terraform destroy -target=module.app_service
```

### Ver Estado

```bash
terraform show                        # Estado completo
terraform state list                  # Listar recursos
terraform state show module.database  # Detalles de un módulo
```

### Refresh Estado

```bash
# Sincronizar estado con Azure
terraform refresh
```

## ⚠️ Troubleshooting

### Error: Backend Configuration Not Found

```bash
# Asegúrate de estar en terraform/environments/dev
pwd

# Verifica que existe backend.tfbackend
ls -la backend.tfbackend

# Si no existe, ejecuta setup-backend.sh
../../scripts/setup-backend.sh
```

### Error: terraform.tfvars Not Found

```bash
# Copia el ejemplo
cp terraform.tfvars.example terraform.tfvars

# Edita con tus valores
nano terraform.tfvars
```

### Error: Insufficient Permissions

```bash
# Verifica tu rol en la suscripción
az role assignment list --assignee $(az account show --query user.name -o tsv) \
                        --subscription 353a6255-27a8-4733-adf0-1c531ba9f4e9

# Necesitas rol: Contributor o Owner
```

### Error: Resource Already Exists

```bash
# Si algún recurso ya existe, impórtalo
terraform import module.networking.azurerm_virtual_network.main /subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/...

# O elimínalo manualmente y vuelve a ejecutar apply
```

### Error: Naming Collision (Storage Account)

El nombre de Storage Account debe ser único globalmente. Si falla:

```bash
# Terraform genera un sufijo aleatorio, pero puede colisionar
# Solución: Destruir y volver a crear (genera nuevo sufijo)
terraform destroy -target=module.storage
terraform apply
```

### Error: PostgreSQL Password Requirements

```
Error: Invalid password: must be at least 8 characters and contain uppercase, lowercase, and numbers
```

Solución: Edita `terraform.tfvars`:
```hcl
postgres_admin_password = "MySecure123!"  # Correcto
# postgres_admin_password = "simple"       # Incorrecto
```

## 📞 Soporte

- **Documentación Terraform**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- **Azure CLI Reference**: https://learn.microsoft.com/cli/azure/
- **Issues del proyecto**: https://github.com/AlbertoLacambra/mindful-moments-infrastructure/issues

## 📚 Referencias

- [AZURE_SRE_AGENT_PROJECT_SPEC.md](../../AZURE_SRE_AGENT_PROJECT_SPEC.md) - Especificación completa
- [PROJECT_INSTRUCTIONS.md](../../PROJECT_INSTRUCTIONS.md) - Plan de implementación 5 semanas
- [README.md](../../README.md) - Overview del proyecto

---

**Estado actual**: ✅ FASE 1 - Setup Inicial Completada

**Próximo milestone**: FASE 2 - Desarrollo de aplicación "Mindful Moments"
