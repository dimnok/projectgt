-- Create contractor_bank_accounts table
CREATE TABLE IF NOT EXISTS public.contractor_bank_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contractor_id UUID NOT NULL REFERENCES public.contractors(id) ON DELETE CASCADE,
    bank_name TEXT NOT NULL,
    bik TEXT,
    corr_account TEXT,
    account_number TEXT NOT NULL,
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.contractor_bank_accounts ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY contractor_bank_accounts_select ON public.contractor_bank_accounts
    FOR SELECT
    USING (check_permission(auth.uid(), 'contractors'::text, 'read'::text));

CREATE POLICY contractor_bank_accounts_insert ON public.contractor_bank_accounts
    FOR INSERT
    WITH CHECK (check_permission(auth.uid(), 'contractors'::text, 'create'::text));

CREATE POLICY contractor_bank_accounts_update ON public.contractor_bank_accounts
    FOR UPDATE
    USING (check_permission(auth.uid(), 'contractors'::text, 'update'::text));

CREATE POLICY contractor_bank_accounts_delete ON public.contractor_bank_accounts
    FOR DELETE
    USING (check_permission(auth.uid(), 'contractors'::text, 'delete'::text));

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_contractor_bank_accounts_updated_at
    BEFORE UPDATE ON public.contractor_bank_accounts
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

