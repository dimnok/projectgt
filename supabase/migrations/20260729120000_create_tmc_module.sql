-- Модуль ТМЦ: справочники, позиции, единицы, остатки, операции, вложения.
-- Аддитивно: не изменяет существующие таблицы приложения.

BEGIN;

-- ---------------------------------------------------------------------------
-- Склады
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tmc_warehouses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    address TEXT,
    description TEXT,
    is_archived BOOLEAN NOT NULL DEFAULT false,
    archived_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID REFERENCES auth.users(id),
    CONSTRAINT tmc_warehouses_name_company_uq UNIQUE (company_id, name)
);

CREATE INDEX IF NOT EXISTS idx_tmc_warehouses_company
    ON public.tmc_warehouses (company_id) WHERE is_archived = false;

-- ---------------------------------------------------------------------------
-- Категории (дерево)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tmc_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES public.tmc_categories(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    code TEXT,
    sort_order INT NOT NULL DEFAULT 0,
    is_archived BOOLEAN NOT NULL DEFAULT false,
    archived_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID REFERENCES auth.users(id),
    CONSTRAINT tmc_categories_name_parent_company_uq UNIQUE NULLS NOT DISTINCT (company_id, parent_id, name)
);

CREATE INDEX IF NOT EXISTS idx_tmc_categories_company
    ON public.tmc_categories (company_id, parent_id) WHERE is_archived = false;

-- ---------------------------------------------------------------------------
-- Состояния
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tmc_conditions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    is_system BOOLEAN NOT NULL DEFAULT false,
    is_archived BOOLEAN NOT NULL DEFAULT false,
    archived_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID REFERENCES auth.users(id),
    CONSTRAINT tmc_conditions_code_company_uq UNIQUE (company_id, code)
);

CREATE INDEX IF NOT EXISTS idx_tmc_conditions_company
    ON public.tmc_conditions (company_id) WHERE is_archived = false;

-- ---------------------------------------------------------------------------
-- Последовательность инвентарных номеров
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tmc_inventory_number_seq (
    company_id UUID PRIMARY KEY REFERENCES public.companies(id) ON DELETE CASCADE,
    last_value BIGINT NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- Позиции каталога
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tmc_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category_id UUID REFERENCES public.tmc_categories(id) ON DELETE SET NULL,
    subcategory_id UUID REFERENCES public.tmc_categories(id) ON DELETE SET NULL,
    accounting_type TEXT NOT NULL DEFAULT 'individual',
    sku TEXT,
    manufacturer TEXT,
    model TEXT,
    unit_of_measure TEXT NOT NULL DEFAULT 'шт',
    description TEXT,
    photo_url TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    delivery_date DATE,
    acceptance_date DATE,
    supplier_id UUID REFERENCES public.contractors(id) ON DELETE SET NULL,
    document_number TEXT,
    unit_price NUMERIC(14, 2) NOT NULL DEFAULT 0 CHECK (unit_price >= 0),
    quantity NUMERIC(14, 3) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    total_cost NUMERIC(14, 2) GENERATED ALWAYS AS (
        round(unit_price * quantity, 2)
    ) STORED,
    vat_amount NUMERIC(14, 2) NOT NULL DEFAULT 0 CHECK (vat_amount >= 0),
    warranty_until DATE,
    is_archived BOOLEAN NOT NULL DEFAULT false,
    archived_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID REFERENCES auth.users(id),
    CONSTRAINT tmc_items_accounting_type_chk CHECK (
        accounting_type IN ('individual', 'quantitative')
    ),
    CONSTRAINT tmc_items_status_chk CHECK (status IN ('active', 'archived'))
);

CREATE INDEX IF NOT EXISTS idx_tmc_items_company
    ON public.tmc_items (company_id) WHERE is_archived = false;
CREATE INDEX IF NOT EXISTS idx_tmc_items_category
    ON public.tmc_items (company_id, category_id);
CREATE INDEX IF NOT EXISTS idx_tmc_items_name
    ON public.tmc_items (company_id, name);

-- ---------------------------------------------------------------------------
-- Единицы (индивидуальный учёт)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tmc_units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES public.tmc_items(id) ON DELETE CASCADE,
    inventory_number TEXT NOT NULL,
    serial_number TEXT,
    barcode TEXT,
    purchase_date DATE,
    purchase_price NUMERIC(14, 2) NOT NULL DEFAULT 0 CHECK (purchase_price >= 0),
    condition_id UUID REFERENCES public.tmc_conditions(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'in_stock',
    location_type TEXT NOT NULL DEFAULT 'warehouse',
    warehouse_id UUID REFERENCES public.tmc_warehouses(id) ON DELETE SET NULL,
    object_id UUID REFERENCES public.objects(id) ON DELETE SET NULL,
    employee_id UUID REFERENCES public.employees(id) ON DELETE SET NULL,
    location_note TEXT,
    usage_object_id UUID REFERENCES public.objects(id) ON DELETE SET NULL,
    responsible_employee_id UUID REFERENCES public.employees(id) ON DELETE SET NULL,
    last_issue_date DATE,
    next_inspection_date DATE,
    warranty_until DATE,
    comment TEXT,
    photo_url TEXT,
    is_archived BOOLEAN NOT NULL DEFAULT false,
    archived_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID REFERENCES auth.users(id),
    CONSTRAINT tmc_units_inventory_company_uq UNIQUE (company_id, inventory_number),
    CONSTRAINT tmc_units_status_chk CHECK (
        status IN (
            'in_stock', 'on_object', 'issued', 'temporarily_transferred',
            'in_repair', 'in_service', 'reserved', 'lost', 'written_off'
        )
    ),
    CONSTRAINT tmc_units_location_type_chk CHECK (
        location_type IN ('warehouse', 'object', 'employee', 'office', 'repair_org', 'other')
    )
);

CREATE INDEX IF NOT EXISTS idx_tmc_units_company_item
    ON public.tmc_units (company_id, item_id) WHERE is_archived = false;
CREATE INDEX IF NOT EXISTS idx_tmc_units_status
    ON public.tmc_units (company_id, status);
CREATE INDEX IF NOT EXISTS idx_tmc_units_employee
    ON public.tmc_units (company_id, employee_id) WHERE employee_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Остатки (количественный учёт)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tmc_balances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES public.tmc_items(id) ON DELETE CASCADE,
    location_type TEXT NOT NULL,
    warehouse_id UUID REFERENCES public.tmc_warehouses(id) ON DELETE CASCADE,
    object_id UUID REFERENCES public.objects(id) ON DELETE CASCADE,
    employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE,
    location_note TEXT,
    quantity NUMERIC(14, 3) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    reserved_quantity NUMERIC(14, 3) NOT NULL DEFAULT 0 CHECK (reserved_quantity >= 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT tmc_balances_location_type_chk CHECK (
        location_type IN ('warehouse', 'object', 'employee', 'office', 'repair_org', 'other')
    ),
    CONSTRAINT tmc_balances_qty_reserved_chk CHECK (reserved_quantity <= quantity)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_tmc_balances_unique_loc
    ON public.tmc_balances (
        company_id,
        item_id,
        location_type,
        COALESCE(warehouse_id, '00000000-0000-0000-0000-000000000000'::uuid),
        COALESCE(object_id, '00000000-0000-0000-0000-000000000000'::uuid),
        COALESCE(employee_id, '00000000-0000-0000-0000-000000000000'::uuid),
        COALESCE(location_note, '')
    );

CREATE INDEX IF NOT EXISTS idx_tmc_balances_item
    ON public.tmc_balances (company_id, item_id);

-- ---------------------------------------------------------------------------
-- Операции
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tmc_operations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    operation_type TEXT NOT NULL,
    operated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    document_number TEXT,
    basis TEXT,
    comment TEXT,
    from_location_type TEXT,
    from_warehouse_id UUID REFERENCES public.tmc_warehouses(id) ON DELETE SET NULL,
    from_object_id UUID REFERENCES public.objects(id) ON DELETE SET NULL,
    from_employee_id UUID REFERENCES public.employees(id) ON DELETE SET NULL,
    from_location_note TEXT,
    to_location_type TEXT,
    to_warehouse_id UUID REFERENCES public.tmc_warehouses(id) ON DELETE SET NULL,
    to_object_id UUID REFERENCES public.objects(id) ON DELETE SET NULL,
    to_employee_id UUID REFERENCES public.employees(id) ON DELETE SET NULL,
    to_location_note TEXT,
    responsible_employee_id UUID REFERENCES public.employees(id) ON DELETE SET NULL,
    object_id UUID REFERENCES public.objects(id) ON DELETE SET NULL,
    reverses_operation_id UUID REFERENCES public.tmc_operations(id) ON DELETE SET NULL,
    planned_return_date DATE,
    condition_id UUID REFERENCES public.tmc_conditions(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID REFERENCES auth.users(id),
    CONSTRAINT tmc_operations_type_chk CHECK (
        operation_type IN (
            'receipt', 'issue', 'return_from_employee',
            'transfer_to_object', 'return_from_object',
            'move_between_objects', 'move_between_warehouses',
            'transfer_between_employees',
            'reserve', 'unreserve',
            'send_to_repair', 'return_from_repair',
            'change_condition', 'inventory_adjust',
            'write_off', 'shortage', 'correction'
        )
    )
);

CREATE INDEX IF NOT EXISTS idx_tmc_operations_company
    ON public.tmc_operations (company_id, operated_at DESC);
CREATE INDEX IF NOT EXISTS idx_tmc_operations_type
    ON public.tmc_operations (company_id, operation_type);

CREATE TABLE IF NOT EXISTS public.tmc_operation_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    operation_id UUID NOT NULL REFERENCES public.tmc_operations(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES public.tmc_items(id) ON DELETE RESTRICT,
    unit_id UUID REFERENCES public.tmc_units(id) ON DELETE SET NULL,
    quantity NUMERIC(14, 3) NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price NUMERIC(14, 2),
    condition_id UUID REFERENCES public.tmc_conditions(id) ON DELETE SET NULL,
    completeness_note TEXT,
    comment TEXT,
    -- Спецодежда
    clothing_size TEXT,
    height_cm NUMERIC(6, 1),
    season TEXT,
    service_life_days INT,
    next_replacement_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tmc_operation_items_operation
    ON public.tmc_operation_items (operation_id);
CREATE INDEX IF NOT EXISTS idx_tmc_operation_items_item
    ON public.tmc_operation_items (company_id, item_id);

-- ---------------------------------------------------------------------------
-- История состояний
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tmc_condition_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    unit_id UUID REFERENCES public.tmc_units(id) ON DELETE CASCADE,
    item_id UUID REFERENCES public.tmc_items(id) ON DELETE CASCADE,
    previous_condition_id UUID REFERENCES public.tmc_conditions(id) ON DELETE SET NULL,
    new_condition_id UUID NOT NULL REFERENCES public.tmc_conditions(id) ON DELETE RESTRICT,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    comment TEXT,
    photo_url TEXT,
    operation_id UUID REFERENCES public.tmc_operations(id) ON DELETE SET NULL,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tmc_condition_history_unit
    ON public.tmc_condition_history (unit_id, changed_at DESC);

-- ---------------------------------------------------------------------------
-- Активные выдачи
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tmc_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES public.tmc_items(id) ON DELETE CASCADE,
    unit_id UUID REFERENCES public.tmc_units(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES public.employees(id) ON DELETE RESTRICT,
    object_id UUID REFERENCES public.objects(id) ON DELETE SET NULL,
    quantity NUMERIC(14, 3) NOT NULL DEFAULT 1 CHECK (quantity > 0),
    issued_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    planned_return_date DATE,
    condition_id UUID REFERENCES public.tmc_conditions(id) ON DELETE SET NULL,
    issue_operation_id UUID REFERENCES public.tmc_operations(id) ON DELETE SET NULL,
    clothing_size TEXT,
    height_cm NUMERIC(6, 1),
    season TEXT,
    service_life_days INT,
    next_replacement_date DATE,
    comment TEXT,
    returned_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID REFERENCES auth.users(id)
);

CREATE INDEX IF NOT EXISTS idx_tmc_assignments_active
    ON public.tmc_assignments (company_id, employee_id) WHERE is_active = true;
CREATE UNIQUE INDEX IF NOT EXISTS idx_tmc_assignments_active_unit
    ON public.tmc_assignments (unit_id) WHERE is_active = true AND unit_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Вложения
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tmc_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    item_id UUID REFERENCES public.tmc_items(id) ON DELETE CASCADE,
    unit_id UUID REFERENCES public.tmc_units(id) ON DELETE CASCADE,
    operation_id UUID REFERENCES public.tmc_operations(id) ON DELETE CASCADE,
    repair_id UUID,
    write_off_id UUID,
    inventory_id UUID,
    file_type TEXT NOT NULL DEFAULT 'other',
    file_name TEXT,
    storage_path TEXT NOT NULL,
    mime_type TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID REFERENCES auth.users(id),
    CONSTRAINT tmc_attachments_file_type_chk CHECK (
        file_type IN (
            'photo', 'invoice', 'receipt', 'warranty', 'write_off_act',
            'repair_doc', 'inventory_doc', 'other'
        )
    )
);

CREATE INDEX IF NOT EXISTS idx_tmc_attachments_item
    ON public.tmc_attachments (item_id) WHERE item_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Ремонты
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tmc_repairs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES public.tmc_items(id) ON DELETE CASCADE,
    unit_id UUID REFERENCES public.tmc_units(id) ON DELETE SET NULL,
    sent_at DATE NOT NULL DEFAULT CURRENT_DATE,
    reason TEXT,
    fault_description TEXT,
    repair_org_name TEXT,
    responsible_employee_id UUID REFERENCES public.employees(id) ON DELETE SET NULL,
    estimated_cost NUMERIC(14, 2) CHECK (estimated_cost IS NULL OR estimated_cost >= 0),
    actual_cost NUMERIC(14, 2) CHECK (actual_cost IS NULL OR actual_cost >= 0),
    completed_at DATE,
    result TEXT,
    condition_after_id UUID REFERENCES public.tmc_conditions(id) ON DELETE SET NULL,
    repair_warranty_until DATE,
    status TEXT NOT NULL DEFAULT 'open',
    send_operation_id UUID REFERENCES public.tmc_operations(id) ON DELETE SET NULL,
    return_operation_id UUID REFERENCES public.tmc_operations(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID REFERENCES auth.users(id),
    CONSTRAINT tmc_repairs_status_chk CHECK (status IN ('open', 'completed', 'cancelled'))
);

CREATE INDEX IF NOT EXISTS idx_tmc_repairs_company
    ON public.tmc_repairs (company_id, status);

-- ---------------------------------------------------------------------------
-- Списания
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tmc_write_offs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES public.tmc_items(id) ON DELETE CASCADE,
    unit_id UUID REFERENCES public.tmc_units(id) ON DELETE SET NULL,
    written_off_at DATE NOT NULL DEFAULT CURRENT_DATE,
    reason TEXT NOT NULL,
    quantity NUMERIC(14, 3) NOT NULL DEFAULT 1 CHECK (quantity > 0),
    condition_id UUID REFERENCES public.tmc_conditions(id) ON DELETE SET NULL,
    book_value NUMERIC(14, 2) CHECK (book_value IS NULL OR book_value >= 0),
    responsible_employee_id UUID REFERENCES public.employees(id) ON DELETE SET NULL,
    object_id UUID REFERENCES public.objects(id) ON DELETE SET NULL,
    act_number TEXT,
    comment TEXT,
    operation_id UUID REFERENCES public.tmc_operations(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID REFERENCES auth.users(id),
    CONSTRAINT tmc_write_offs_reason_chk CHECK (
        reason IN (
            'wear', 'breakdown', 'loss', 'shortage',
            'obsolescence', 'end_of_life', 'other'
        )
    )
);

CREATE INDEX IF NOT EXISTS idx_tmc_write_offs_company
    ON public.tmc_write_offs (company_id, written_off_at DESC);

-- ---------------------------------------------------------------------------
-- Инвентаризация
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tmc_inventories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    scope_type TEXT NOT NULL DEFAULT 'company',
    warehouse_id UUID REFERENCES public.tmc_warehouses(id) ON DELETE SET NULL,
    object_id UUID REFERENCES public.objects(id) ON DELETE SET NULL,
    employee_id UUID REFERENCES public.employees(id) ON DELETE SET NULL,
    category_id UUID REFERENCES public.tmc_categories(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'draft',
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID REFERENCES auth.users(id),
    CONSTRAINT tmc_inventories_scope_chk CHECK (
        scope_type IN ('company', 'warehouse', 'object', 'employee', 'category', 'items')
    ),
    CONSTRAINT tmc_inventories_status_chk CHECK (
        status IN ('draft', 'in_progress', 'completed', 'cancelled')
    )
);

CREATE TABLE IF NOT EXISTS public.tmc_inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    inventory_id UUID NOT NULL REFERENCES public.tmc_inventories(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES public.tmc_items(id) ON DELETE CASCADE,
    unit_id UUID REFERENCES public.tmc_units(id) ON DELETE SET NULL,
    system_quantity NUMERIC(14, 3) NOT NULL DEFAULT 0,
    actual_quantity NUMERIC(14, 3),
    surplus NUMERIC(14, 3) GENERATED ALWAYS AS (
        CASE
            WHEN actual_quantity IS NULL THEN NULL
            ELSE GREATEST(actual_quantity - system_quantity, 0)
        END
    ) STORED,
    shortage NUMERIC(14, 3) GENERATED ALWAYS AS (
        CASE
            WHEN actual_quantity IS NULL THEN NULL
            ELSE GREATEST(system_quantity - actual_quantity, 0)
        END
    ) STORED,
    condition_id UUID REFERENCES public.tmc_conditions(id) ON DELETE SET NULL,
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tmc_inventory_items_inv
    ON public.tmc_inventory_items (inventory_id);

-- ---------------------------------------------------------------------------
-- Уведомления in-app
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tmc_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    notification_type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    item_id UUID REFERENCES public.tmc_items(id) ON DELETE SET NULL,
    unit_id UUID REFERENCES public.tmc_units(id) ON DELETE SET NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT tmc_notifications_type_chk CHECK (
        notification_type IN (
            'warranty_expiring', 'service_due', 'return_due',
            'not_returned', 'needs_repair', 'ppe_replacement',
            'shortage', 'no_movement', 'other'
        )
    )
);

CREATE INDEX IF NOT EXISTS idx_tmc_notifications_user
    ON public.tmc_notifications (company_id, user_id, is_read, created_at DESC);

-- FK для attachments → repairs / write_offs / inventories
ALTER TABLE public.tmc_attachments
    DROP CONSTRAINT IF EXISTS tmc_attachments_repair_id_fkey;
ALTER TABLE public.tmc_attachments
    ADD CONSTRAINT tmc_attachments_repair_id_fkey
    FOREIGN KEY (repair_id) REFERENCES public.tmc_repairs(id) ON DELETE CASCADE;

ALTER TABLE public.tmc_attachments
    DROP CONSTRAINT IF EXISTS tmc_attachments_write_off_id_fkey;
ALTER TABLE public.tmc_attachments
    ADD CONSTRAINT tmc_attachments_write_off_id_fkey
    FOREIGN KEY (write_off_id) REFERENCES public.tmc_write_offs(id) ON DELETE CASCADE;

ALTER TABLE public.tmc_attachments
    DROP CONSTRAINT IF EXISTS tmc_attachments_inventory_id_fkey;
ALTER TABLE public.tmc_attachments
    ADD CONSTRAINT tmc_attachments_inventory_id_fkey
    FOREIGN KEY (inventory_id) REFERENCES public.tmc_inventories(id) ON DELETE CASCADE;

-- ---------------------------------------------------------------------------
-- updated_at triggers
-- ---------------------------------------------------------------------------
DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'tmc_warehouses', 'tmc_categories', 'tmc_conditions', 'tmc_items',
        'tmc_units', 'tmc_operations', 'tmc_assignments', 'tmc_repairs',
        'tmc_write_offs', 'tmc_inventories', 'tmc_inventory_items'
    ]
    LOOP
        EXECUTE format(
            'DROP TRIGGER IF EXISTS trg_%s_updated_at ON public.%I;
             CREATE TRIGGER trg_%s_updated_at
             BEFORE UPDATE ON public.%I
             FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();',
            t, t, t, t
        );
    END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- Seed категорий и состояний для всех компаний
-- ---------------------------------------------------------------------------
INSERT INTO public.tmc_categories (company_id, name, code, sort_order, created_by)
SELECT c.id, v.name, v.code, v.sort_order, NULL
FROM public.companies c
CROSS JOIN (VALUES
    ('Инструмент', 'tool', 10),
    ('Спецодежда', 'workwear', 20),
    ('Оргтехника', 'office_equipment', 30),
    ('Средства индивидуальной защиты', 'ppe', 40),
    ('Измерительные приборы', 'measuring', 50),
    ('Прочее', 'other', 60)
) AS v(name, code, sort_order)
WHERE NOT EXISTS (
    SELECT 1 FROM public.tmc_categories tc
    WHERE tc.company_id = c.id AND tc.code = v.code AND tc.parent_id IS NULL
);

INSERT INTO public.tmc_conditions (company_id, code, name, sort_order, is_system)
SELECT c.id, v.code, v.name, v.sort_order, true
FROM public.companies c
CROSS JOIN (VALUES
    ('new', 'Новое', 10),
    ('good', 'Исправное', 20),
    ('satisfactory', 'Удовлетворительное', 30),
    ('needs_service', 'Требует обслуживания', 40),
    ('needs_repair', 'Требует ремонта', 50),
    ('in_repair', 'В ремонте', 60),
    ('faulty', 'Неисправное', 70),
    ('lost', 'Утеряно', 80),
    ('written_off', 'Списано', 90)
) AS v(code, name, sort_order)
WHERE NOT EXISTS (
    SELECT 1 FROM public.tmc_conditions tc
    WHERE tc.company_id = c.id AND tc.code = v.code
);

-- ---------------------------------------------------------------------------
-- RLS helper macro pattern
-- ---------------------------------------------------------------------------
DO $$
DECLARE
    tbl TEXT;
    tables TEXT[] := ARRAY[
        'tmc_warehouses', 'tmc_categories', 'tmc_conditions', 'tmc_items',
        'tmc_units', 'tmc_balances', 'tmc_operations', 'tmc_operation_items',
        'tmc_condition_history', 'tmc_assignments', 'tmc_attachments',
        'tmc_repairs', 'tmc_write_offs', 'tmc_inventories', 'tmc_inventory_items',
        'tmc_notifications', 'tmc_inventory_number_seq'
    ];
BEGIN
    FOREACH tbl IN ARRAY tables
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl);

        EXECUTE format('DROP POLICY IF EXISTS "tmc_select_%s" ON public.%I', tbl, tbl);
        EXECUTE format(
            'CREATE POLICY "tmc_select_%s" ON public.%I FOR SELECT TO authenticated
             USING (
               company_id IN (SELECT public.get_my_company_ids())
               AND public.check_permission(auth.uid(), ''tmc'', ''read'')
             )', tbl, tbl
        );

        EXECUTE format('DROP POLICY IF EXISTS "tmc_insert_%s" ON public.%I', tbl, tbl);
        EXECUTE format(
            'CREATE POLICY "tmc_insert_%s" ON public.%I FOR INSERT TO authenticated
             WITH CHECK (
               company_id IN (SELECT public.get_my_company_ids())
               AND public.check_permission(auth.uid(), ''tmc'', ''create'')
             )', tbl, tbl
        );

        EXECUTE format('DROP POLICY IF EXISTS "tmc_update_%s" ON public.%I', tbl, tbl);
        EXECUTE format(
            'CREATE POLICY "tmc_update_%s" ON public.%I FOR UPDATE TO authenticated
             USING (
               company_id IN (SELECT public.get_my_company_ids())
               AND public.check_permission(auth.uid(), ''tmc'', ''update'')
             )
             WITH CHECK (
               company_id IN (SELECT public.get_my_company_ids())
               AND public.check_permission(auth.uid(), ''tmc'', ''update'')
             )', tbl, tbl
        );

        EXECUTE format('DROP POLICY IF EXISTS "tmc_delete_%s" ON public.%I', tbl, tbl);
        EXECUTE format(
            'CREATE POLICY "tmc_delete_%s" ON public.%I FOR DELETE TO authenticated
             USING (
               company_id IN (SELECT public.get_my_company_ids())
               AND public.check_permission(auth.uid(), ''tmc'', ''delete'')
             )', tbl, tbl
        );
    END LOOP;
END $$;

-- Операции: create достаточно для проведения (остатки меняет RPC SECURITY DEFINER)
DROP POLICY IF EXISTS "tmc_insert_tmc_operations" ON public.tmc_operations;
CREATE POLICY "tmc_insert_tmc_operations"
ON public.tmc_operations FOR INSERT TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND (
        public.check_permission(auth.uid(), 'tmc', 'create')
        OR public.check_permission(auth.uid(), 'tmc', 'issue')
        OR public.check_permission(auth.uid(), 'tmc', 'move')
        OR public.check_permission(auth.uid(), 'tmc', 'repair')
        OR public.check_permission(auth.uid(), 'tmc', 'write_off')
        OR public.check_permission(auth.uid(), 'tmc', 'inventory')
    )
);

DROP POLICY IF EXISTS "tmc_insert_tmc_operation_items" ON public.tmc_operation_items;
CREATE POLICY "tmc_insert_tmc_operation_items"
ON public.tmc_operation_items FOR INSERT TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND (
        public.check_permission(auth.uid(), 'tmc', 'create')
        OR public.check_permission(auth.uid(), 'tmc', 'issue')
        OR public.check_permission(auth.uid(), 'tmc', 'move')
        OR public.check_permission(auth.uid(), 'tmc', 'repair')
        OR public.check_permission(auth.uid(), 'tmc', 'write_off')
        OR public.check_permission(auth.uid(), 'tmc', 'inventory')
    )
);

-- Справочники: manage_catalogs
DROP POLICY IF EXISTS "tmc_insert_tmc_warehouses" ON public.tmc_warehouses;
DROP POLICY IF EXISTS "tmc_update_tmc_warehouses" ON public.tmc_warehouses;
CREATE POLICY "tmc_insert_tmc_warehouses"
ON public.tmc_warehouses FOR INSERT TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND (
        public.check_permission(auth.uid(), 'tmc', 'manage_catalogs')
        OR public.check_permission(auth.uid(), 'tmc', 'create')
    )
);
CREATE POLICY "tmc_update_tmc_warehouses"
ON public.tmc_warehouses FOR UPDATE TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND (
        public.check_permission(auth.uid(), 'tmc', 'manage_catalogs')
        OR public.check_permission(auth.uid(), 'tmc', 'update')
    )
)
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND (
        public.check_permission(auth.uid(), 'tmc', 'manage_catalogs')
        OR public.check_permission(auth.uid(), 'tmc', 'update')
    )
);

DROP POLICY IF EXISTS "tmc_insert_tmc_categories" ON public.tmc_categories;
DROP POLICY IF EXISTS "tmc_update_tmc_categories" ON public.tmc_categories;
CREATE POLICY "tmc_insert_tmc_categories"
ON public.tmc_categories FOR INSERT TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'tmc', 'manage_catalogs')
);
CREATE POLICY "tmc_update_tmc_categories"
ON public.tmc_categories FOR UPDATE TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'tmc', 'manage_catalogs')
)
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'tmc', 'manage_catalogs')
);

DROP POLICY IF EXISTS "tmc_insert_tmc_conditions" ON public.tmc_conditions;
DROP POLICY IF EXISTS "tmc_update_tmc_conditions" ON public.tmc_conditions;
CREATE POLICY "tmc_insert_tmc_conditions"
ON public.tmc_conditions FOR INSERT TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'tmc', 'manage_catalogs')
);
CREATE POLICY "tmc_update_tmc_conditions"
ON public.tmc_conditions FOR UPDATE TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'tmc', 'manage_catalogs')
)
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'tmc', 'manage_catalogs')
);

-- Уведомления: пользователь видит свои
DROP POLICY IF EXISTS "tmc_select_tmc_notifications" ON public.tmc_notifications;
CREATE POLICY "tmc_select_tmc_notifications"
ON public.tmc_notifications FOR SELECT TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND (
        user_id = auth.uid()
        OR public.check_permission(auth.uid(), 'tmc', 'read')
    )
);

DROP POLICY IF EXISTS "tmc_update_tmc_notifications" ON public.tmc_notifications;
CREATE POLICY "tmc_update_tmc_notifications"
ON public.tmc_notifications FOR UPDATE TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND (user_id = auth.uid() OR public.check_permission(auth.uid(), 'tmc', 'update'))
)
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND (user_id = auth.uid() OR public.check_permission(auth.uid(), 'tmc', 'update'))
);

-- Запрет прямого изменения остатков клиентом (только RPC)
REVOKE INSERT, UPDATE, DELETE ON public.tmc_balances FROM authenticated;
GRANT SELECT ON public.tmc_balances TO authenticated;

-- ---------------------------------------------------------------------------
-- app_modules
-- ---------------------------------------------------------------------------
INSERT INTO public.app_modules (code, name, icon_key, sort_order, is_active)
VALUES ('tmc', 'ТМЦ', 'cube_box', 55, true)
ON CONFLICT (code) DO UPDATE
SET
    name = EXCLUDED.name,
    icon_key = EXCLUDED.icon_key,
    sort_order = EXCLUDED.sort_order,
    is_active = true;

COMMIT;

-- Storage bucket (applied separately on server if needed)
-- See migration create_tmc_storage_bucket via MCP.
