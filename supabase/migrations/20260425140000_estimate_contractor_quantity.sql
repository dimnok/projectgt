-- Объём, выделенный подрядчику по позиции; частичный импорт (цена и/или объём).
-- unit_price допускает NULL, если в файле заполнен только объём.

BEGIN;

ALTER TABLE public.estimate_contractor_prices
    ADD COLUMN IF NOT EXISTS contractor_quantity DOUBLE PRECISION;

COMMENT ON COLUMN public.estimate_contractor_prices.contractor_quantity IS
    'Объём работ/материала, отнесённый к подрядчику по строке сметы (в ед. изм. позиции). NULL — не задано отдельно.';

ALTER TABLE public.estimate_contractor_prices
    DROP CONSTRAINT IF EXISTS estimate_contractor_prices_unit_price_non_negative;

ALTER TABLE public.estimate_contractor_prices
    ALTER COLUMN unit_price DROP NOT NULL;

ALTER TABLE public.estimate_contractor_prices
    ADD CONSTRAINT estimate_contractor_prices_unit_price_non_negative
        CHECK (unit_price IS NULL OR unit_price >= 0::double precision);

ALTER TABLE public.estimate_contractor_prices
    ADD CONSTRAINT estimate_contractor_prices_contractor_quantity_non_negative
        CHECK (
            contractor_quantity IS NULL
            OR contractor_quantity >= 0::double precision
        );

COMMIT;
