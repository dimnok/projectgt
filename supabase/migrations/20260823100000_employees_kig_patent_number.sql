-- Документы иностранных граждан: КИГ и номер патента (необязательные).
ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS kig TEXT,
  ADD COLUMN IF NOT EXISTS patent_number TEXT;

COMMENT ON COLUMN public.employees.kig IS
  'КИГ иностранного гражданина. Необязательное текстовое поле.';

COMMENT ON COLUMN public.employees.patent_number IS
  'Номер патента на работу. Необязательное текстовое поле.';
