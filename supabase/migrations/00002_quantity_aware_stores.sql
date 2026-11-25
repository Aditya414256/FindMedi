-- =============================================================================
-- FindMedicine — Quantity-Aware Store Availability & Pricing
-- =============================================================================

-- Drop old uuid[] signatures so PostgREST resolves the new jsonb signatures cleanly
DROP FUNCTION IF EXISTS public.nearby_stores(double precision, double precision, double precision, uuid[]);
DROP FUNCTION IF EXISTS public.stores_for_pincode(text, uuid[]);

-- 1. nearby_stores — find stores within a radius using the haversine formula,
--    checking stock >= requested quantity and computing price * quantity.
CREATE OR REPLACE FUNCTION public.nearby_stores(
  user_lat   double precision,
  user_lng   double precision,
  radius_km  double precision DEFAULT 5,
  p_items    jsonb            DEFAULT '[]'::jsonb
)
RETURNS TABLE (
  store_id          uuid,
  store_name        text,
  address           text,
  lat               double precision,
  lng               double precision,
  is_open           boolean,
  offers_delivery   boolean,
  distance_km       double precision,
  total_price       numeric,
  missing_medicines text[],
  low_stock_items   jsonb
) AS $$
BEGIN
  RETURN QUERY
  WITH requested AS (
    SELECT
      (item->>'medicine_id')::uuid AS mid,
      GREATEST(1, COALESCE((item->>'quantity')::integer, 1)) AS qty
    FROM jsonb_array_elements(COALESCE(p_items, '[]'::jsonb)) AS item
  ),
  store_distances AS (
    SELECT
      s.id, s.name, s.address, s.lat, s.lng, s.is_open, s.offers_delivery,
      (6371 * acos(
        LEAST(1.0,
          cos(radians(user_lat)) * cos(radians(s.lat)) *
          cos(radians(s.lng) - radians(user_lng)) +
          sin(radians(user_lat)) * sin(radians(s.lat))
        )
      )) AS dist_km
    FROM public.stores s
  ),
  filtered AS (
    SELECT * FROM store_distances WHERE dist_km <= radius_km
  ),
  inventory_check AS (
    SELECT
      f.id AS sid,
      COALESCE(SUM(CASE WHEN si.medicine_id IS NOT NULL AND si.stock >= r.qty THEN si.price * r.qty ELSE 0 END), 0) AS tp,
      ARRAY_AGG(m.name) FILTER (WHERE si.medicine_id IS NULL OR si.stock < r.qty) AS missing,
      COALESCE(
        jsonb_agg(
          jsonb_build_object(
            'medicine_id', r.mid,
            'medicine_name', m.name,
            'available_stock', si.stock,
            'requested_quantity', r.qty
          )
        ) FILTER (WHERE si.medicine_id IS NOT NULL AND si.stock > 0 AND si.stock < r.qty),
        '[]'::jsonb
      ) AS low_stock
    FROM filtered f
    CROSS JOIN requested r
    LEFT JOIN public.store_inventory si
      ON si.store_id = f.id AND si.medicine_id = r.mid
    LEFT JOIN public.medicines m ON m.id = r.mid
    GROUP BY f.id
  )
  SELECT
    f.id,
    f.name,
    f.address,
    f.lat,
    f.lng,
    f.is_open,
    f.offers_delivery,
    ROUND(f.dist_km::numeric, 2)::double precision,
    COALESCE(ic.tp, 0),
    COALESCE(ic.missing, '{}'),
    COALESCE(ic.low_stock, '[]'::jsonb)
  FROM filtered f
  LEFT JOIN inventory_check ic ON ic.sid = f.id
  ORDER BY
    (CASE WHEN COALESCE(array_length(ic.missing, 1), 0) = 0 THEN 0 ELSE 1 END),
    f.dist_km;
END;
$$ LANGUAGE plpgsql STABLE;


-- 2. stores_for_pincode — find delivery-capable stores that service a pincode,
--    checking stock >= requested quantity and computing price * quantity.
CREATE OR REPLACE FUNCTION public.stores_for_pincode(
  p_pincode  text,
  p_items    jsonb DEFAULT '[]'::jsonb
)
RETURNS TABLE (
  store_id          uuid,
  store_name        text,
  address           text,
  lat               double precision,
  lng               double precision,
  is_open           boolean,
  offers_delivery   boolean,
  distance_km       double precision,
  total_price       numeric,
  missing_medicines text[],
  low_stock_items   jsonb
) AS $$
BEGIN
  RETURN QUERY
  WITH requested AS (
    SELECT
      (item->>'medicine_id')::uuid AS mid,
      GREATEST(1, COALESCE((item->>'quantity')::integer, 1)) AS qty
    FROM jsonb_array_elements(COALESCE(p_items, '[]'::jsonb)) AS item
  ),
  matching_stores AS (
    SELECT s.*
    FROM public.stores s
    WHERE s.offers_delivery = true
      AND p_pincode = ANY(s.serviceable_pincodes)
  ),
  inventory_check AS (
    SELECT
      ms.id AS sid,
      COALESCE(SUM(CASE WHEN si.medicine_id IS NOT NULL AND si.stock >= r.qty THEN si.price * r.qty ELSE 0 END), 0) AS tp,
      ARRAY_AGG(m.name) FILTER (WHERE si.medicine_id IS NULL OR si.stock < r.qty) AS missing,
      COALESCE(
        jsonb_agg(
          jsonb_build_object(
            'medicine_id', r.mid,
            'medicine_name', m.name,
            'available_stock', si.stock,
            'requested_quantity', r.qty
          )
        ) FILTER (WHERE si.medicine_id IS NOT NULL AND si.stock > 0 AND si.stock < r.qty),
        '[]'::jsonb
      ) AS low_stock
    FROM matching_stores ms
    CROSS JOIN requested r
    LEFT JOIN public.store_inventory si
      ON si.store_id = ms.id AND si.medicine_id = r.mid
    LEFT JOIN public.medicines m ON m.id = r.mid
    GROUP BY ms.id
  )
  SELECT
    ms.id,
    ms.name,
    ms.address,
    ms.lat,
    ms.lng,
    ms.is_open,
    ms.offers_delivery,
    0.0::double precision,
    COALESCE(ic.tp, 0),
    COALESCE(ic.missing, '{}'),
    COALESCE(ic.low_stock, '[]'::jsonb)
  FROM matching_stores ms
  LEFT JOIN inventory_check ic ON ic.sid = ms.id
  ORDER BY
    (CASE WHEN COALESCE(array_length(ic.missing, 1), 0) = 0 THEN 0 ELSE 1 END),
    ms.name;
END;
$$ LANGUAGE plpgsql STABLE;

GRANT EXECUTE ON FUNCTION public.nearby_stores(double precision, double precision, double precision, jsonb) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.stores_for_pincode(text, jsonb) TO anon, authenticated, service_role;
