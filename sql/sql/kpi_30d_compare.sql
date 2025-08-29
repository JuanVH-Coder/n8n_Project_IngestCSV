-- KPI 30d vs 30d prev (GLOBAL) - Revenue = Conversions * 100
-- Salida: C:/data/ads/out/kpi_30d_compare.csv

COPY (
  WITH anchor AS (SELECT MAX(date) AS maxd FROM ads_spend),

  win AS (
    SELECT
      CASE
        WHEN date > (SELECT maxd - INTERVAL 60 DAY FROM anchor)
             AND date <= (SELECT maxd - INTERVAL 30 DAY FROM anchor) THEN 'prev_30'
        WHEN date > (SELECT maxd - INTERVAL 30 DAY FROM anchor)
             AND date <= (SELECT maxd FROM anchor)                       THEN 'last_30'
      END AS win,
      spend,
      conversions
    FROM ads_spend
    WHERE date > (SELECT maxd - INTERVAL 60 DAY FROM anchor)
  ),

  agg AS (
    SELECT win, SUM(spend) AS spend, SUM(conversions) AS conv
    FROM win
    GROUP BY win
  ),

  -- Colapsamos agg a una sola fila con las 4 cifras base
  calc AS (
    SELECT
      MAX(CASE WHEN win='last_30' THEN spend END) AS spend_last30,
      MAX(CASE WHEN win='prev_30' THEN spend END) AS spend_prev30,
      MAX(CASE WHEN win='last_30' THEN conv  END) AS conv_last30,
      MAX(CASE WHEN win='prev_30' THEN conv  END) AS conv_prev30
    FROM agg
  )

  SELECT
    ROUND(spend_last30,2)                                    AS spend_last30,
    ROUND(spend_prev30,2)                                    AS spend_prev30,
    ROUND(spend_last30 - spend_prev30,2)                     AS spend_delta_abs,
    ROUND(CASE WHEN spend_prev30>0
               THEN (spend_last30 - spend_prev30)/spend_prev30 * 100 END, 2)
                                                            AS spend_delta_pct,

    conv_last30,
    conv_prev30,
    (conv_last30 - conv_prev30)                              AS conv_delta_abs,
    ROUND(CASE WHEN conv_prev30>0
               THEN (conv_last30 - conv_prev30)/conv_prev30 * 100 END, 2)
                                                            AS conv_delta_pct,

    ROUND(CASE WHEN conv_last30>0 THEN spend_last30/conv_last30 END, 2)
                                                            AS cac_last30,
    ROUND(CASE WHEN conv_prev30>0 THEN spend_prev30/conv_prev30 END, 2)
                                                            AS cac_prev30,
    ROUND(
      (CASE WHEN conv_last30>0 THEN spend_last30/conv_last30 END)
      -
      (CASE WHEN conv_prev30>0 THEN spend_prev30/conv_prev30 END)
    , 2)                                                     AS cac_delta_abs,
    ROUND(CASE
      WHEN (CASE WHEN conv_prev30>0 THEN spend_prev30/conv_prev30 END) IS NOT NULL
           AND (CASE WHEN conv_prev30>0 THEN spend_prev30/conv_prev30 END) <> 0
      THEN (
        (CASE WHEN conv_last30>0 THEN spend_last30/conv_last30 END)
        -
        (CASE WHEN conv_prev30>0 THEN spend_prev30/conv_prev30 END)
      )
      /
      (CASE WHEN conv_prev30>0 THEN spend_prev30/conv_prev30 END) * 100
    END, 2)                                                  AS cac_delta_pct,

    ROUND(CASE WHEN spend_last30>0 THEN (conv_last30*100)/spend_last30 END, 2)
                                                            AS roas_last30,
    ROUND(CASE WHEN spend_prev30>0 THEN (conv_prev30*100)/spend_prev30 END, 2)
                                                            AS roas_prev30,
    ROUND(
      (CASE WHEN spend_last30>0 THEN (conv_last30*100)/spend_last30 END)
      -
      (CASE WHEN spend_prev30>0 THEN (conv_prev30*100)/spend_prev30 END)
    , 2)                                                     AS roas_delta_abs,
    ROUND(CASE
      WHEN (CASE WHEN spend_prev30>0 THEN (conv_prev30*100)/spend_prev30 END) IS NOT NULL
           AND (CASE WHEN spend_prev30>0 THEN (conv_prev30*100)/spend_prev30 END) <> 0
      THEN (
        (CASE WHEN spend_last30>0 THEN (conv_last30*100)/spend_last30 END)
        -
        (CASE WHEN spend_prev30>0 THEN (conv_prev30*100)/spend_prev30 END)
      )
      /
      (CASE WHEN spend_prev30>0 THEN (conv_prev30*100)/spend_prev30 END) * 100
    END, 2)  
    
  FROM calc
) TO 'C:/data/ads/out/kpi_30d_compare.csv' WITH (HEADER, DELIMITER ',');
