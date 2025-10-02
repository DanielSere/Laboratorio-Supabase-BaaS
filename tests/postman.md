# Colección Postman: Taller Supabase


## 🔐 Variables de Entorno

| Variable | Valor | Descripción |
|----------|-------|-------------|
| `SUPABASE_URL` | `https://ocymjndkrcajkxlaxtvj.supabase.co` | URL del proyecto Supabase |
| `SUPABASE_ANON_KEY` | `eyJhbGci...` | Clave anónima de Supabase |
| `USER_CR_BEARER_TOKEN` | `Bearer eyJhbGci...` | Token de usuario CR (Costa Rica) |
| `USER_US_BEARER_TOKEN` | `Bearer eyJhbGci...` | Token de usuario US (Estados Unidos) |

## 📊 Endpoints Disponibles

### 1. 🔐 Autenticación

#### **Obtener Token de Usuario CR**
- **Método:** `POST`
- **URL:** `{{SUPABASE_URL}}/auth/v1/token?grant_type=password`
- **Headers:**
  - `apikey`: `{{SUPABASE_ANON_KEY}}`
- **Body:**
  ```json
  {
    "email": "user_cr@example.com",
    "password": "12345"
  }
  ```

### 2. 📦 Productos (RLS por Categoría)

#### **Listar Productos - RLS CR**
- **Método:** `GET`
- **URL:** `{{SUPABASE_URL}}/rest/v1/products?select=*&category_id=eq.1`
- **Headers:**
  - `Authorization`: `{{USER_CR_BEARER_TOKEN}}`
  - `apikey`: `{{SUPABASE_ANON_KEY}}`

### 3. 👥 Clientes (RLS por País)

#### **Clientes por País - RLS CR**
- **Método:** `GET`
- **URL:** `{{SUPABASE_URL}}/rest/v1/customers?select=*&country_code=eq.CR`
- **Headers:**
  - `Authorization`: `{{USER_CR_BEARER_TOKEN}}`
  - `apikey`: `{{SUPABASE_ANON_KEY}}`

### 4. 🧾 Facturas

#### **Facturas con Cliente Embebido - RLS CR**
- **Método:** `GET`
- **URL:** `{{SUPABASE_URL}}/rest/v1/invoices?select=*,customers(*)`
- **Headers:**
  - `Authorization`: `{{USER_CR_BEARER_TOKEN}}`
  - `apikey`: `{{SUPABASE_ANON_KEY}}`

#### **Crear Factura - RLS CR**
- **Método:** `POST`
- **URL:** `{{SUPABASE_URL}}/rest/v1/invoices`
- **Headers:**
  - `Authorization`: `{{USER_CR_BEARER_TOKEN}}`
  - `apikey`: `{{SUPABASE_ANON_KEY}}`
- **Body:**
  ```json
  { "customer_id": 1 }
  ```

### 5. 📝 Líneas de Factura

#### **Detalle con Producto Embebido - RLS CR**
- **Método:** `GET`
- **URL:** `{{SUPABASE_URL}}/rest/v1/invoice_lines?select=*,products(*)`
- **Headers:**
  - `Authorization`: `{{USER_CR_BEARER_TOKEN}}`
  - `apikey`: `{{SUPABASE_ANON_KEY}}`

#### **Crear Línea de Factura - RLS CR**
- **Método:** `POST`
- **URL:** `{{SUPABASE_URL}}/rest/v1/invoice_lines`
- **Headers:**
  - `Authorization`: `{{USER_CR_BEARER_TOKEN}}`
  - `apikey`: `{{SUPABASE_ANON_KEY}}`
- **Body:**
  ```json
  {
    "invoice_id": 15,
    "product_id": 1,
    "quantity": 2,
    "unit_price": 299.99,
    "line_total": 599.98
  }
  ```

### 6. ⚡ Función RPC (Transacción Atómica)

#### **Crear Factura Completa - RLS CR**
- **Método:** `POST`
- **URL:** `{{SUPABASE_URL}}/rest/v1/rpc/create_invoice`
- **Headers:**
  - `Authorization`: `{{USER_CR_BEARER_TOKEN}}`
  - `apikey`: `{{SUPABASE_ANON_KEY}}`
- **Body:**
  ```json
  {
    "customer_id": 1,
    "items": [
      { "product_id": 1, "quantity": 2 }
    ]
  }
  ```

### 7. 📈 Reportes y Vistas

#### **Ventas por País - RLS CR**
- **Método:** `GET`
- **URL:** `{{SUPABASE_URL}}/rest/v1/v_sales_by_country?select=*&country_code=eq.CR`
- **Headers:**
  - `Authorization`: `{{USER_CR_BEARER_TOKEN}}`
  - `apikey`: `{{SUPABASE_ANON_KEY}}`

#### **Hechos de Ventas - RLS CR**
- **Método:** `GET`
- **URL:** `{{SUPABASE_URL}}/rest/v1/v_sales_fact`
- **Headers:**
  - `Authorization`: `{{USER_CR_BEARER_TOKEN}}`
  - `apikey`: `{{SUPABASE_ANON_KEY}}`

#### **Ventas por Categoría - RLS CR**
- **Método:** `GET`
- **URL:** `{{SUPABASE_URL}}/rest/v1/v_sales_by_category`
- **Headers:**
  - `Authorization`: `{{USER_CR_BEARER_TOKEN}}`
  - `apikey`: `{{SUPABASE_ANON_KEY}}`

#### **Top Productos (30 días) - RLS CR**
- **Método:** `GET`
- **URL:** `{{SUPABASE_URL}}/rest/v1/v_top_products_30d`
- **Headers:**
  - `Authorization`: `{{USER_CR_BEARER_TOKEN}}`
  - `apikey`: `{{SUPABASE_ANON_KEY}}`

## 🔒 Reglas de Seguridad (RLS) Implementadas

### **Productos:**
- Usuarios solo ven productos de categorías permitidas
- Políticas aplicadas: SELECT, INSERT, UPDATE, DELETE

### **Clientes:**
- Usuarios solo ven clientes de países permitidos
- Política aplicada: SELECT

### **Facturas:**
- Usuarios solo ven facturas de clientes de países permitidos
- Política aplicada: SELECT

### **Líneas de Factura:**
- **Doble verificación RLS:**
  1. Factura debe ser de cliente de país permitido
  2. Producto debe ser de categoría permitida
- Políticas aplicadas: SELECT, INSERT, UPDATE, DELETE

