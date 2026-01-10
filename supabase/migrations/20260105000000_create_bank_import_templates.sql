CREATE TABLE IF NOT EXISTS public.bank_import_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    bank_name TEXT NOT NULL,
    column_mapping JSONB NOT NULL,
    start_row INTEGER NOT NULL DEFAULT 1,
    date_format TEXT NOT NULL DEFAULT 'dd.MM.yyyy',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.bank_import_templates ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view templates of their companies" 
ON public.bank_import_templates 
FOR SELECT 
USING (company_id IN (SELECT get_my_company_ids()));

CREATE POLICY "Users can insert templates for their companies" 
ON public.bank_import_templates 
FOR INSERT 
WITH CHECK (company_id IN (SELECT get_my_company_ids()));

CREATE POLICY "Users can update templates of their companies" 
ON public.bank_import_templates 
FOR UPDATE 
USING (company_id IN (SELECT get_my_company_ids()));

CREATE POLICY "Users can delete templates of their companies" 
ON public.bank_import_templates 
FOR DELETE 
USING (company_id IN (SELECT get_my_company_ids()));

-- Trigger for updated_at
CREATE TRIGGER set_updated_at_bank_import_templates
BEFORE UPDATE ON public.bank_import_templates
FOR EACH ROW
EXECUTE FUNCTION public.handle_updated_at();

-- Comment on table
COMMENT ON TABLE public.bank_import_templates IS 'Шаблоны маппинга колонок Excel для импорта банковских выписок.';

