-- 1) STAGING desde el CSV
DROP TABLE IF EXISTS _stg_ads_spend;
CREATE TEMP TABLE _stg_ads_spend AS
SELECT
  TRY_CAST(date AS DATE)                                   AS date,
  platform,
  account,
  campaign,
  country,
  device,
  TRY_CAST(spend       AS DOUBLE)                          AS spend,
  TRY_CAST(clicks      AS INTEGER)                         AS clicks,
  TRY_CAST(impressions AS BIGINT)                          AS impressions,
  TRY_CAST(conversions AS INTEGER)                         AS conversions,
  now()                                                    AS load_date,         -- metadato
  'ads_spend.csv'                                          AS source_file_name   -- metadato
FROM read_csv_auto('C:/data/ads/ads_spend.csv', HEADER=TRUE);

-- 2) Tabla destino (si no existe)
CREATE TABLE IF NOT EXISTS ads_spend (
  date DATE,
  platform VARCHAR,
  account VARCHAR,
  campaign VARCHAR,
  country VARCHAR,
  device VARCHAR,
  spend DOUBLE,
  clicks INTEGER,
  impressions BIGINT,
  conversions INTEGER,
  load_date TIMESTAMP WITH TIME ZONE,
  source_file_name VARCHAR
);

-- 3) Insertar SOLO filas nuevas (idempotente / evita duplicados)
INSERT INTO ads_spend
SELECT s.*
FROM _stg_ads_spend s
WHERE NOT EXISTS (
  SELECT 1
  FROM ads_spend d
  WHERE d.date      = s.date
    AND d.platform  = s.platform
    AND d.account   = s.account
    AND d.campaign  = s.campaign
    AND d.country   = s.country
    AND d.device    = s.device
);

-- 4) Chequeo rápido (salida a consola)
SELECT COUNT(*) AS total_rows FROM ads_spend;
