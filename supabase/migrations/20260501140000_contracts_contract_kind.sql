-- Тип договора: заказчик (входящий), подряд (исходящий на исполнение), поставка.
ALTER TABLE public.contracts
ADD COLUMN IF NOT EXISTS contract_kind text NOT NULL DEFAULT 'customer'
CHECK (contract_kind IN ('customer', 'subcontract', 'supply'));

COMMENT ON COLUMN public.contracts.contract_kind IS 'Тип участия контрагента: customer — заказчик, subcontract — подряд/субподряд, supply — поставка';
