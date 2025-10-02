# README — App de consola Python (Cliente Supabase)

Aplicación de consola para interactuar con un proyecto Supabase (lista productos, clientes, crear facturas, agregar líneas, mostrar facturas).

---

## Contenido

* `main.py` — script principal.
* `.env` — variables de entorno.

---

## Requisitos

* Python 3.8+
* pip
* Dependencias Python:

```bash
pip install -r requirements.txt
```


---

## Variables de entorno (obligatorias)

Define estas variables en tu entorno **antes** de ejecutar la app, o crea un archivo `.env` y usa `python-dotenv`:

```
SUPABASE_URL=https://<tu-proyecto>.supabase.co
SUPABASE_ANON_KEY=<tu-anon-key>
USER_EMAIL=<usuario_de_prueba_email>
USER_PASSWORD=<contraseña_del_usuario>
```


---

## Cómo ejecutar

1. Clona / copia el archivo `main.py` en tu proyecto.
2. Asegúrate de haber exportado las variables de entorno o de tener `.env` y `python-dotenv` instalado.
3. Ejecuta:

```bash
python main.py
```

---

## Menú principal (qué hace cada opción)

Al ejecutar, verás el menú interactivo:

1. **Listar productos**

   * Llama `GET /rest/v1/products` (RLS aplicado).
2. **Listar clientes**

   * Llama `GET /rest/v1/customers` (RLS aplicado).
3. **Crear factura (interactivo)**

   * Pide `Customer ID`, crea la factura (insert en `invoices`) y permite agregar líneas (insert en `invoice_lines`).
4. **Mostrar factura con líneas**

   * Muestra `invoices` y `invoice_lines` filtrados por `invoice_id`.
5. **Salir**

---

## Flujo típico para crear una factura

1. Seleccionar opción 3.
2. Ingresar `Customer ID` (ej. `1`).
3. Se crea la invoice y devuelve `invoice_id` (si RLS/INSERT lo permite).
4. Agregar líneas:

   * `Product ID` (0 para terminar)
   * `Cantidad`
   * `Unit price`
     (La app inserta cada línea y muestra el resultado).

