-- Артикул в позициях заявки на закупку.

BEGIN;

ALTER TABLE public.purchase_request_items
    ADD COLUMN IF NOT EXISTS article TEXT;

COMMIT;
