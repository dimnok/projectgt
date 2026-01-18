# Аудит перехода на company_id (RBAC v3)

Модуль Работы
- works ✅ (есть company_id)
- work_hours ✅ (есть company_id)
- work_items ✅ (есть company_id)
- work_materials ✅ (есть company_id)
- work_plans ✅ (есть company_id)
- work_plan_blocks ✅ (есть company_id)
- work_plan_items ✅ (есть company_id)

Модуль Объекты
- objects ✅ (есть company_id)

Модуль Сотрудники
- employees ✅ (есть company_id)
- employee_attendance ✅ (есть company_id)
- employee_rates ✅ (есть company_id)
- business_trip_rates ✅ (есть company_id)

Модуль Контрагенты и Договоры
- contractors ✅ (есть company_id)
- contractor_bank_accounts ✅ (есть company_id)
- contracts ✅ (есть company_id)
- contract_files ✅ (есть company_id)

Модуль Сметы и Акты
- estimates ✅ (есть company_id)
- ks2_acts ✅ (есть company_id)

Модуль Материалы
- materials ✅ (есть company_id)
- material_aliases ✅ (есть company_id)
- kit_components ✅ (есть company_id)

Модуль Финансы (Cash Flow / Payroll)
- cash_flow ✅ (есть company_id)
- cash_flow_categories ✅ (есть company_id)
- bank_import_templates ✅ (есть company_id)
- bank_statement_entries ✅ (есть company_id)
- payroll_bonus ✅ (есть company_id)
- payroll_payout ✅ (есть company_id)
- payroll_penalty ✅ (есть company_id)
- receipts ✅ (есть company_id)

Модуль Система и Доступы
- companies ❌ (НЕТ company_id - корневая таблица)
- company_members ✅ (есть company_id)
- company_bank_accounts ✅ (есть company_id)
- company_documents ✅ (есть company_id)
- profiles ✅ (Изоляция через RLS: Coworkers only)
- user_tokens ❌ (НЕТ company_id)
- roles ✅ (есть company_id)
- role_permissions ✅ (есть company_id)
- app_modules ❌ (НЕТ company_id)
- app_versions ❌ (НЕТ company_id)
