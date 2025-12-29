-- Добавление RLS политик для модуля "Компания"
-- Позволяет аутентифицированным пользователям управлять данными компании

-- Политики для company_profile
CREATE POLICY "Allow update for all authorized users" ON "public"."company_profile"
FOR UPDATE TO authenticated
USING (true)
WITH CHECK (true);

-- Политики для company_bank_accounts
CREATE POLICY "Allow insert for all authorized users" ON "public"."company_bank_accounts"
FOR INSERT TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow update for all authorized users" ON "public"."company_bank_accounts"
FOR UPDATE TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Allow delete for all authorized users" ON "public"."company_bank_accounts"
FOR DELETE TO authenticated
USING (true);

-- Политики для company_documents
CREATE POLICY "Allow insert for all authorized users" ON "public"."company_documents"
FOR INSERT TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow update for all authorized users" ON "public"."company_documents"
FOR UPDATE TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Allow delete for all authorized users" ON "public"."company_documents"
FOR DELETE TO authenticated
USING (true);

