#!/usr/bin/env python3

import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

URL = os.getenv("SUPABASE_URL")
KEY = os.getenv("SUPABASE_ANON_KEY")
EMAIL = os.getenv("USER_EMAIL")
PWD = os.getenv("USER_PASSWORD")


# --- funciones base ---

def login() -> Client:
    sb: Client = create_client(URL, KEY)
    auth = sb.auth.sign_in_with_password({"email": EMAIL, "password":PWD})
    if not auth.session:
        raise SystemExit("Login failed.")
        print("Logged in:", auth.user.email)
    return sb


def list_my_products(sb: Client):
    res = sb.table("products").select("*").execute()
    print("Products (RLS applied):", res.data)

def list_my_customers(sb: Client):
    res = sb.table("customers").select("*").execute()
    print("Customers (RLS applied):", res.data)

def create_invoice(sb: Client, customer_id: int):
    try:
        res = sb.table("invoices").insert({"customer_id": customer_id}).execute()
    except Exception as e:
        print("Error al insertar invoice:", e)
        return None

    data = res.data
    # si la insert devolvió la fila
    if data:
        # data puede ser lista o dict
        if isinstance(data, list) and len(data) > 0:
            row = data[0]
        elif isinstance(data, dict):
            row = data
        else:
            row = None
        if row and row.get("id"):
            print("Invoice creada:", row)
            return row["id"]
    return None

def add_line(sb: Client, invoice_id: int, product_id: int, qty: float, unit_price: float):
    line_total = round(float(qty) * float(unit_price), 2)
    payload = {
        "invoice_id": invoice_id,
        "product_id": product_id,
        "quantity": qty,
        "unit_price": unit_price,
        "line_total": line_total,
    }

    # insertar línea
    try:
        res = sb.table("invoice_lines").insert(payload).execute()
    except Exception as e:
        print("Error insertando invoice_line:", e)
        return None

    print("Line creada:", res.data or res)

    # recalcular total sumando las line_total de la factura
    try:
        res_lines = sb.table("invoice_lines").select("line_total").eq("invoice_id", invoice_id).execute()
        rows = res_lines.data or []
        total = sum(float(r.get("line_total") or 0) for r in rows)
        # actualizar invoice
        upd = sb.table("invoices").update({"total_amount": round(total, 2)}).eq("id", invoice_id).execute()
        print("Invoice actualizada total_amount:", round(total, 2), upd.data)
    except Exception as e:
        print("Error recalculando/actualizando total:", e)

    return res.data

def show_invoice_with_lines(sb: Client, invoice_id: int):
    inv = sb.table("invoices").select("*").eq("id", invoice_id).execute()
    lines = sb.table("invoice_lines").select("*").eq("invoice_id", invoice_id).execute()
    print("Invoice:", inv.data)
    print("Lines:", lines.data)



# --- Menu de consola que llama a tus funciones base ---

def input_int(prompt: str) -> int:
    while True:
        v = input(prompt).strip()
        try:
            return int(v)
        except Exception:
            print("Ingresa un número entero válido.")

def input_float(prompt: str) -> float:
    while True:
        v = input(prompt).strip()
        try:
            return float(v)
        except Exception:
            print("Ingresa un número válido (ej: 12.5)")

def crear_factura_interactiva(sb: Client):
    print("\n--- Crear nueva factura (usando funciones originales) ---")
    customer_id = input_int("Customer ID: ")
    # crear invoice (usando create_invoice original)
    try:
        invoice_id = create_invoice(sb, customer_id)
    except Exception as e:
        print("Error creando invoice:", e)
        return

    # agregar líneas iterativamente
    while True:
        print("\nAgregar línea (ingresa 0 como Product ID para terminar)")
        pid = input_int("Product ID: ")
        if pid == 0:
            break
        qty = input_float("Cantidad: ")
        unit_price = input_float("Unit price: ")
        try:
            add_line(sb, invoice_id, pid, qty, unit_price)
        except Exception as e:
            print("Error agregando línea:", e)

    print(f"Factura {invoice_id} creada. Puedes usar 'Mostrar factura con líneas' para verificar.")

def main_menu(sb: Client):
    while True:
        print("\n=== Menú ===")
        print("1) Listar productos")
        print("2) Listar clientes")
        print("3) Crear factura")
        print("4) Mostrar factura con líneas")
        print("5) Salir")
        opt = input("Selecciona opción: ").strip()
        if opt == "1":
            list_my_products(sb)
        elif opt == "2":
            list_my_customers(sb)
        elif opt == "3":
            crear_factura_interactiva(sb)
        elif opt == "4":
            iid = input_int("Invoice ID: ")
            show_invoice_with_lines(sb, iid)
        elif opt == "5":
            print("Saliendo. ¡Adiós!")
            break
        else:
            print("Opción inválida. Intenta de nuevo.")

if __name__ == "__main__":
    # validación básica de variables de entorno
    if not all([URL, KEY, EMAIL, PWD]):
        print("Define SUPABASE_URL, SUPABASE_ANON_KEY, USER_EMAIL y USER_PASSWORD en las variables de entorno.")
        raise SystemExit(1)

    client = login()
    main_menu(client)

