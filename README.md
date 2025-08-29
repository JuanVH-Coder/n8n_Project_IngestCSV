n8n_Proyecto_IngestCSV

Proyecto completo para:

Ingestar un CSV de anuncios en DuckDB

Hacer QA de datos (conteos, nulls, fechas, duplicados, etc.)

Calcular KPIs (CAC y ROAS) comparando últimos 30 días vs 30 días anteriores

Exponer los resultados por API REST con n8n

(Extra) Un endpoint NL de demostración que devuelve un mensaje + tabla con CAC/ROAS

0) Requisitos

n8n (Desktop o self-host).

DuckDB CLI instalado.

Un CSV con columnas mínimas:

date, platform, account, campaign, country, device, spend, clicks, impressions, conversions


SO usado: Windows (si usas macOS/Linux, cambia rutas C:\... por tu ruta local).

1) Estructura del repo
/
├─ README.md
├─ LICENSE
├─ .gitignore
├─ sql/
│  ├─ ingest_ads.sql           ← ingesta + normalización + QA
│  └─ kpi_30d_compare.sql      ← KPIs CAC/ROAS (30d vs 30d prev)
├─ n8n/
│  └─ ads_ingest_workflow.json ← workflow exportado listo para importar
├─ results/                    ← salidas ligeras de ejemplo
│  ├─ kpi_30d_compare.csv
│  └─ ingestion_log.csv
└─ screenshots/                ← capturas
   ├─ api_kpis_json.png
   └─ api_nl_json.png


No subo ads.duckdb ni toda la carpeta out/ para no llenar el repo de binarios.

2) Carpeta local y archivos

Así lo tengo en mi máquina:

C:\data\ads\
├─ ads_spend.csv          ← tu CSV de entrada
├─ ads.duckdb             ← base DuckDB (se crea al ejecutar)
├─ sql\                   ← aquí puedo copiar los .sql del repo
└─ out\                   ← DuckDB y n8n escriben aquí los resultados


Importante: si usas otras rutas, ajústalas en los .sql y en los nodos del workflow n8n.

3) Lógica de negocio

Ventanas:

last30: desde max(date) − 29 días hasta max(date).

prev30: los 30 días inmediatamente anteriores a last30.

Revenue (supuesto): conversions × 100.
(Si tienes revenue real, cambia la fórmula en kpi_30d_compare.sql).

KPI CAC: CAC = spend / conversions (si conversions > 0, si no → NULL).

KPI ROAS: ROAS = (conversions × 100) / spend (si spend > 0, si no → NULL).

Deltas:

delta_abs = last30 − prev30

delta_pct = (delta_abs / prev30) × 100 (si prev30 != 0)

QA principal (en ingest_ads.sql):

filas cargadas en staging vs finales

duplicados

valores nulos por métrica clave

fechas mínima y máxima en datos

filas ejemplo y esquema de columnas

4) Ejecutar DuckDB (ingesta + QA + KPIs)
4.1 Ingesta + QA
duckdb "C:\data\ads\ads.duckdb" -c ".read 'C:\data\ads\sql\ingest_ads.sql'"


Qué hace ingest_ads.sql:

Crea una tabla staging tipada a partir de ads_spend.csv.

Deduplica a ads_spend (claves compuestas: date,platform,account,campaign,country,device).

Exporta QA a C:\data\ads\out\, por ejemplo:

schema.csv

metrics.csv (nulls, negativos, etc.)

qa_summary.csv

sample_rows.csv, sample10.csv

rows_in_db.csv (conteo final)

ingestion_log.csv (log de persistencia)

4.2 KPIs (CAC/ROAS) 30d vs 30d prev
duckdb "C:\data\ads\ads.duckdb" -c ".read 'C:\data\ads\sql\kpi_30d_compare.sql'"


Salida principal:

C:\data\ads\out\kpi_30d_compare.csv

Estructura típica:

metric	last30	prev30	delta_abs	delta_pct
CAC	29.8	32.18	-2.38	-7.41%
ROAS	3.36	3.11	0.25	8.00%
5) Importar y correr el workflow de n8n
5.1 Importar

Abre n8n → Import → From File.

Selecciona: n8n/ads_ingest_workflow.json.

Si tus rutas no son C:\data\ads\..., abre los nodos relevantes y cámbialas:

Execute Command (invoca DuckDB con .sql)

Read/Write Files from Disk (lee C:\data\ads\out\...)

Extract from CSV (extrae y transforma a JSON)

5.2 Qué hace el flujo (resumen)

(Opcional) HTTP Request: descargar CSV.

Read/Write Files: escribe/lee de C:\data\ads\out\.

Execute Command: llama a DuckDB con ingest_ads.sql y kpi_30d_compare.sql.

Extract from CSV: convierte salidas a items JSON.

Code: da formato a la tabla de KPIs.

Webhook + Respond to Webhook:

GET /ads/kpis → JSON con KPIs (tabla compacta).

GET /ads/nl → JSON con message + table (demo “NL”).

6) Probar los endpoints del workflow

En el nodo Webhook (el de /ads/kpis), pulsa Listen for test event.
Copia la Test URL (algo como http://localhost:5678/webhook-test/ads/kpis) y ábrela en el navegador.
⇒ verás el JSON con KPIs.

Repite con el otro Webhook (el NL):
http://localhost:5678/webhook-test/ads/nl
⇒ verás algo como:

{
  "intent": "compare_cac_roas_30d",
  "message": "Comparando *últimos 30 días vs 30 días anteriores*: CAC: 29.8 vs 32.18 (-2.38, -7.41%). ROAS: 3.36 vs 3.11 (0.25, 8.00).",
  "table": [
    {"metric":"CAC","last30":29.8,"prev30":32.18,"delta_abs":-2.38,"delta_pct":"-7.41%"},
    {"metric":"ROAS","last30":3.36,"prev30":3.11,"delta_abs":0.25,"delta_pct":"8.00%"}
  ]
}


Para Production URL, usa la otra pestaña del Webhook y activa el workflow.

7) Entregables (lo que piden)

Acceso n8n

Entrego el JSON del flujo: n8n/ads_ingest_workflow.json

(Opcional) Mis endpoints locales:

Test: http://localhost:5678/webhook-test/ads/kpis y /ads/nl

Production: la URL que muestra el nodo Webhook

URL del repositorio de GitHub (público)

Incluye:

sql/ingest_ads.sql y sql/kpi_30d_compare.sql (modelos SQL)

n8n/ads_ingest_workflow.json (flujo)

README.md (este documento)

results/ con salidas de ejemplo

screenshots/ con capturas

8) Troubleshooting / Notas

Rutas: si algo no aparece, revisa que las rutas (Windows) sean correctas.
Con espacios:

-c ".read 'C:\ruta con espacios\archivo.sql'"


“Invalid JSON in Response Body” en Respond to Webhook:

Opción 1: en Respond With pon First Incoming Item.

Opción 2: si usas expresión, asegúrate de devolver un objeto JSON (no string). Por ejemplo:

{{ { data: $items().map(i => i.json) } }}


(Si esto te falla, usa First Incoming Item y asegura que el Code node emite un objeto válido).

CAC/ROAS nulos o infinitos: pasa si conversions=0 o spend=0. El SQL ya controla estos divisores y devuelve NULL para evitar errores.

Revenue real: si tienes columna de revenue, cambia la línea en kpi_30d_compare.sql donde calculo revenue como conversions * 100.

9) Checklist rápido (para repetir el proceso)

Poner el CSV en C:\data\ads\ads_spend.csv.

Ejecutar:

duckdb "C:\data\ads\ads.duckdb" -c ".read 'C:\data\ads\sql\ingest_ads.sql'"
duckdb "C:\data\ads\ads.duckdb" -c ".read 'C:\data\ads\sql\kpi_30d_compare.sql'"


Importar n8n/ads_ingest_workflow.json en n8n.

Ajustar rutas en nodos si hace falta.

Correr el workflow y abrir:

http://localhost:5678/webhook-test/ads/kpis

http://localhost:5678/webhook-test/ads/nl

10) Licencia

MIT — ver LICENSE.

Si algo no te corre igual, casi siempre es por ruta de archivos, permisos o divisiones por cero. Con eso resuelto, debería funcionar de punta a punta.
