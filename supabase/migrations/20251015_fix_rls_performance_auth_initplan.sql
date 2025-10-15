-- ===================================================================
-- Миграция: Оптимизация производительности RLS-политик
-- ===================================================================
-- Устраняет предупреждение auth_rls_initplan от Supabase Database Linter
-- 
-- Проблема: вызовы auth.uid(), auth.role(), auth.jwt() пересчитываются
-- для каждой строки, что снижает производительность на больших таблицах.
--
-- Решение: обернуть auth.* функции в подзапросы (SELECT auth.uid())
-- чтобы PostgreSQL вычислял их один раз на запрос.
--
-- Дата: 15 октября 2025
-- ===================================================================

BEGIN;

-- ===================================================================
-- 1. ТАБЛИЦА: works
-- ===================================================================

DROP POLICY IF EXISTS "Allow access to own objects works" ON works;
CREATE POLICY "Allow access to own objects works"
ON works FOR SELECT
TO public
USING (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.id = (SELECT auth.uid())
      AND (p.role = 'admin' OR p.object_ids @> ARRAY[works.object_id])
  )
);

DROP POLICY IF EXISTS "Allow delete for own objects" ON works;
CREATE POLICY "Allow delete for own objects"
ON works FOR DELETE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.id = (SELECT auth.uid())
      AND (p.role = 'admin' OR p.object_ids @> ARRAY[works.object_id])
  )
);

DROP POLICY IF EXISTS "Allow insert for own objects" ON works;
CREATE POLICY "Allow insert for own objects"
ON works FOR INSERT
TO public
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.id = (SELECT auth.uid())
      AND (p.role = 'admin' OR p.object_ids @> ARRAY[works.object_id])
  )
);

DROP POLICY IF EXISTS "Allow update for own objects" ON works;
CREATE POLICY "Allow update for own objects"
ON works FOR UPDATE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.id = (SELECT auth.uid())
      AND (p.role = 'admin' OR p.object_ids @> ARRAY[works.object_id])
  )
);

-- ===================================================================
-- 2. ТАБЛИЦА: work_hours
-- ===================================================================

DROP POLICY IF EXISTS "Allow access to shift_hours via shifts" ON work_hours;
CREATE POLICY "Allow access to shift_hours via shifts"
ON work_hours FOR SELECT
TO public
USING (
  EXISTS (
    SELECT 1
    FROM works s
    WHERE s.id = work_hours.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[s.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow access to work_hours via works" ON work_hours;
CREATE POLICY "Allow access to work_hours via works"
ON work_hours FOR SELECT
TO public
USING (
  EXISTS (
    SELECT 1
    FROM works w
    WHERE w.id = work_hours.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[w.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow delete for shift_hours via shifts" ON work_hours;
CREATE POLICY "Allow delete for shift_hours via shifts"
ON work_hours FOR DELETE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM works s
    WHERE s.id = work_hours.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[s.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow delete for work_hours via works" ON work_hours;
CREATE POLICY "Allow delete for work_hours via works"
ON work_hours FOR DELETE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM works w
    WHERE w.id = work_hours.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[w.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow insert for shift_hours via shifts" ON work_hours;
CREATE POLICY "Allow insert for shift_hours via shifts"
ON work_hours FOR INSERT
TO public
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM works s
    WHERE s.id = work_hours.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[s.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow insert for work_hours via works" ON work_hours;
CREATE POLICY "Allow insert for work_hours via works"
ON work_hours FOR INSERT
TO public
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM works w
    WHERE w.id = work_hours.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[w.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow update for shift_hours via shifts" ON work_hours;
CREATE POLICY "Allow update for shift_hours via shifts"
ON work_hours FOR UPDATE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM works s
    WHERE s.id = work_hours.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[s.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow update for work_hours via works" ON work_hours;
CREATE POLICY "Allow update for work_hours via works"
ON work_hours FOR UPDATE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM works w
    WHERE w.id = work_hours.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[w.object_id])
      )
  )
);

-- ===================================================================
-- 3. ТАБЛИЦА: work_items
-- ===================================================================

DROP POLICY IF EXISTS "Allow access to shift_items via shifts" ON work_items;
CREATE POLICY "Allow access to shift_items via shifts"
ON work_items FOR SELECT
TO public
USING (
  EXISTS (
    SELECT 1
    FROM works s
    WHERE s.id = work_items.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[s.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow access to work_items via works" ON work_items;
CREATE POLICY "Allow access to work_items via works"
ON work_items FOR SELECT
TO public
USING (
  EXISTS (
    SELECT 1
    FROM works w
    WHERE w.id = work_items.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[w.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow delete for shift_items via shifts" ON work_items;
CREATE POLICY "Allow delete for shift_items via shifts"
ON work_items FOR DELETE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM works s
    WHERE s.id = work_items.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[s.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow delete for work_items via works" ON work_items;
CREATE POLICY "Allow delete for work_items via works"
ON work_items FOR DELETE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM works w
    WHERE w.id = work_items.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[w.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow insert for shift_items via shifts" ON work_items;
CREATE POLICY "Allow insert for shift_items via shifts"
ON work_items FOR INSERT
TO public
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM works s
    WHERE s.id = work_items.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[s.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow insert for work_items via works" ON work_items;
CREATE POLICY "Allow insert for work_items via works"
ON work_items FOR INSERT
TO public
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM works w
    WHERE w.id = work_items.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[w.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow update for shift_items via shifts" ON work_items;
CREATE POLICY "Allow update for shift_items via shifts"
ON work_items FOR UPDATE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM works s
    WHERE s.id = work_items.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[s.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow update for work_items via works" ON work_items;
CREATE POLICY "Allow update for work_items via works"
ON work_items FOR UPDATE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM works w
    WHERE w.id = work_items.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[w.object_id])
      )
  )
);

-- ===================================================================
-- 4. ТАБЛИЦА: work_materials
-- ===================================================================

DROP POLICY IF EXISTS "Allow access to shift_materials via shifts" ON work_materials;
CREATE POLICY "Allow access to shift_materials via shifts"
ON work_materials FOR SELECT
TO public
USING (
  EXISTS (
    SELECT 1
    FROM works s
    WHERE s.id = work_materials.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[s.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow access to work_materials via works" ON work_materials;
CREATE POLICY "Allow access to work_materials via works"
ON work_materials FOR SELECT
TO public
USING (
  EXISTS (
    SELECT 1
    FROM works w
    WHERE w.id = work_materials.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[w.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow delete for shift_materials via shifts" ON work_materials;
CREATE POLICY "Allow delete for shift_materials via shifts"
ON work_materials FOR DELETE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM works s
    WHERE s.id = work_materials.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[s.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow delete for work_materials via works" ON work_materials;
CREATE POLICY "Allow delete for work_materials via works"
ON work_materials FOR DELETE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM works w
    WHERE w.id = work_materials.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[w.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow insert for shift_materials via shifts" ON work_materials;
CREATE POLICY "Allow insert for shift_materials via shifts"
ON work_materials FOR INSERT
TO public
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM works s
    WHERE s.id = work_materials.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[s.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow insert for work_materials via works" ON work_materials;
CREATE POLICY "Allow insert for work_materials via works"
ON work_materials FOR INSERT
TO public
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM works w
    WHERE w.id = work_materials.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[w.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow update for shift_materials via shifts" ON work_materials;
CREATE POLICY "Allow update for shift_materials via shifts"
ON work_materials FOR UPDATE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM works s
    WHERE s.id = work_materials.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[s.object_id])
      )
  )
);

DROP POLICY IF EXISTS "Allow update for work_materials via works" ON work_materials;
CREATE POLICY "Allow update for work_materials via works"
ON work_materials FOR UPDATE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM works w
    WHERE w.id = work_materials.work_id
      AND EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND (p.role = 'admin' OR p.object_ids @> ARRAY[w.object_id])
      )
  )
);

-- ===================================================================
-- 5. ТАБЛИЦА: employee_rates
-- ===================================================================

DROP POLICY IF EXISTS "Users can view employee rates" ON employee_rates;
CREATE POLICY "Users can view employee rates"
ON employee_rates FOR SELECT
TO public
USING ((SELECT auth.role()) = 'authenticated');

DROP POLICY IF EXISTS "Only admins can modify employee rates" ON employee_rates;
CREATE POLICY "Only admins can modify employee rates"
ON employee_rates FOR ALL
TO public
USING (
  (SELECT auth.role()) = 'authenticated'
  AND (
    SELECT profiles.role
    FROM profiles
    WHERE profiles.id = (SELECT auth.uid())
  ) = 'admin'
);

-- ===================================================================
-- 6. ТАБЛИЦА: contractors
-- ===================================================================

DROP POLICY IF EXISTS "Allow delete for authenticated" ON contractors;
CREATE POLICY "Allow delete for authenticated"
ON contractors FOR DELETE
TO public
USING ((SELECT auth.role()) = 'authenticated');

DROP POLICY IF EXISTS "Allow insert for authenticated" ON contractors;
CREATE POLICY "Allow insert for authenticated"
ON contractors FOR INSERT
TO public
WITH CHECK ((SELECT auth.role()) = 'authenticated');

DROP POLICY IF EXISTS "Allow read for authenticated" ON contractors;
CREATE POLICY "Allow read for authenticated"
ON contractors FOR SELECT
TO public
USING ((SELECT auth.role()) = 'authenticated');

DROP POLICY IF EXISTS "Allow update for authenticated" ON contractors;
CREATE POLICY "Allow update for authenticated"
ON contractors FOR UPDATE
TO public
USING ((SELECT auth.role()) = 'authenticated');

-- ===================================================================
-- 7. ТАБЛИЦА: estimates
-- ===================================================================

DROP POLICY IF EXISTS "Allow delete for users with access to contract or object" ON estimates;
CREATE POLICY "Allow delete for users with access to contract or object"
ON estimates FOR DELETE
TO public
USING (
  (SELECT auth.role()) = 'service_role'
  OR EXISTS (
    SELECT 1
    FROM contracts c
    WHERE c.id = estimates.contract_id
      AND c.contractor_id = (SELECT auth.uid())
  )
  OR EXISTS (
    SELECT 1
    FROM objects o
    WHERE o.id = estimates.object_id
      AND o.id IN (
        SELECT estimates.object_id
        FROM profiles
        WHERE profiles.id = (SELECT auth.uid())
      )
  )
);

DROP POLICY IF EXISTS "Allow select for users with access to contract or object" ON estimates;
CREATE POLICY "Allow select for users with access to contract or object"
ON estimates FOR SELECT
TO public
USING (
  (SELECT auth.role()) = 'service_role'
  OR EXISTS (
    SELECT 1
    FROM contracts c
    WHERE c.id = estimates.contract_id
      AND c.contractor_id = (SELECT auth.uid())
  )
  OR EXISTS (
    SELECT 1
    FROM objects o
    WHERE o.id = estimates.object_id
      AND o.id IN (
        SELECT estimates.object_id
        FROM profiles
        WHERE profiles.id = (SELECT auth.uid())
      )
  )
);

DROP POLICY IF EXISTS "Allow update for users with access to contract or object" ON estimates;
CREATE POLICY "Allow update for users with access to contract or object"
ON estimates FOR UPDATE
TO public
USING (
  (SELECT auth.role()) = 'service_role'
  OR EXISTS (
    SELECT 1
    FROM contracts c
    WHERE c.id = estimates.contract_id
      AND c.contractor_id = (SELECT auth.uid())
  )
  OR EXISTS (
    SELECT 1
    FROM objects o
    WHERE o.id = estimates.object_id
      AND o.id IN (
        SELECT estimates.object_id
        FROM profiles
        WHERE profiles.id = (SELECT auth.uid())
      )
  )
);

-- ===================================================================
-- 8. ТАБЛИЦА: employees
-- ===================================================================

DROP POLICY IF EXISTS "Only admins can create employees" ON employees;
CREATE POLICY "Only admins can create employees"
ON employees FOR INSERT
TO public
WITH CHECK (
  (SELECT auth.role()) = 'authenticated'
  AND (
    SELECT profiles.role
    FROM profiles
    WHERE profiles.id = (SELECT auth.uid())
  ) = 'admin'
);

DROP POLICY IF EXISTS "Only admins can delete employees" ON employees;
CREATE POLICY "Only admins can delete employees"
ON employees FOR DELETE
TO public
USING (
  (SELECT auth.role()) = 'authenticated'
  AND (
    SELECT profiles.role
    FROM profiles
    WHERE profiles.id = (SELECT auth.uid())
  ) = 'admin'
);

DROP POLICY IF EXISTS "Only admins can update employees" ON employees;
CREATE POLICY "Only admins can update employees"
ON employees FOR UPDATE
TO public
USING (
  (SELECT auth.role()) = 'authenticated'
  AND (
    SELECT profiles.role
    FROM profiles
    WHERE profiles.id = (SELECT auth.uid())
  ) = 'admin'
);

DROP POLICY IF EXISTS "Users can view employees" ON employees;
CREATE POLICY "Users can view employees"
ON employees FOR SELECT
TO public
USING ((SELECT auth.role()) = 'authenticated');

-- ===================================================================
-- 9. ТАБЛИЦА: profiles
-- ===================================================================

DROP POLICY IF EXISTS "Profiles are viewable by authenticated users" ON profiles;
CREATE POLICY "Profiles are viewable by authenticated users"
ON profiles FOR SELECT
TO public
USING ((SELECT auth.role()) = 'authenticated');

DROP POLICY IF EXISTS "Users can update their own profiles" ON profiles;
CREATE POLICY "Users can update their own profiles"
ON profiles FOR UPDATE
TO public
USING ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Admins can update any profile" ON profiles;
CREATE POLICY "Admins can update any profile"
ON profiles FOR UPDATE
TO public
USING (
  (SELECT auth.role()) = 'authenticated'
  AND (
    ((SELECT auth.jwt()) ->> 'role') = 'admin'
    OR EXISTS (
      SELECT 1
      FROM profiles p
      WHERE p.id = (SELECT auth.uid())
        AND p.role = 'admin'
    )
  )
);

-- ===================================================================
-- 10. ТАБЛИЦА: objects
-- ===================================================================

DROP POLICY IF EXISTS "Users can view objects" ON objects;
CREATE POLICY "Users can view objects"
ON objects FOR SELECT
TO public
USING ((SELECT auth.role()) = 'authenticated');

-- ===================================================================
-- 11. ТАБЛИЦА: user_tokens
-- ===================================================================

DROP POLICY IF EXISTS "Users can view own tokens" ON user_tokens;
CREATE POLICY "Users can view own tokens"
ON user_tokens FOR SELECT
TO public
USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own tokens" ON user_tokens;
CREATE POLICY "Users can insert own tokens"
ON user_tokens FOR INSERT
TO public
WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own tokens" ON user_tokens;
CREATE POLICY "Users can delete own tokens"
ON user_tokens FOR DELETE
TO public
USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Rebind token to owner" ON user_tokens;
CREATE POLICY "Rebind token to owner"
ON user_tokens FOR UPDATE
TO public
USING (true)
WITH CHECK ((SELECT auth.uid()) = user_id);

-- ===================================================================
-- 12. ТАБЛИЦА: work_plans
-- ===================================================================

DROP POLICY IF EXISTS "Users can view their own work plans" ON work_plans;
CREATE POLICY "Users can view their own work plans"
ON work_plans FOR SELECT
TO public
USING (
  created_by = (SELECT auth.uid())
  OR object_id IN (
    SELECT unnest(profiles.object_ids)
    FROM profiles
    WHERE profiles.id = (SELECT auth.uid())
  )
  OR EXISTS (
    SELECT 1
    FROM user_roles
    WHERE user_roles.user_id = (SELECT auth.uid())
      AND user_roles.role = 'admin'
  )
);

DROP POLICY IF EXISTS "Users can insert their own work plans" ON work_plans;
CREATE POLICY "Users can insert their own work plans"
ON work_plans FOR INSERT
TO public
WITH CHECK (
  (
    created_by = (SELECT auth.uid())
    AND object_id IN (
      SELECT unnest(profiles.object_ids)
      FROM profiles
      WHERE profiles.id = (SELECT auth.uid())
    )
  )
  OR EXISTS (
    SELECT 1
    FROM user_roles
    WHERE user_roles.user_id = (SELECT auth.uid())
      AND user_roles.role = 'admin'
  )
);

DROP POLICY IF EXISTS "Users can update their own work plans" ON work_plans;
CREATE POLICY "Users can update their own work plans"
ON work_plans FOR UPDATE
TO public
USING (
  created_by = (SELECT auth.uid())
  OR EXISTS (
    SELECT 1
    FROM user_roles
    WHERE user_roles.user_id = (SELECT auth.uid())
      AND user_roles.role = 'admin'
  )
);

DROP POLICY IF EXISTS "Users can delete their own work plans" ON work_plans;
CREATE POLICY "Users can delete their own work plans"
ON work_plans FOR DELETE
TO public
USING (
  created_by = (SELECT auth.uid())
  OR EXISTS (
    SELECT 1
    FROM user_roles
    WHERE user_roles.user_id = (SELECT auth.uid())
      AND user_roles.role = 'admin'
  )
);

-- ===================================================================
-- 13. ТАБЛИЦА: work_plan_blocks
-- ===================================================================

DROP POLICY IF EXISTS "Blocks: read" ON work_plan_blocks;
CREATE POLICY "Blocks: read"
ON work_plan_blocks FOR SELECT
TO public
USING (
  EXISTS (
    SELECT 1
    FROM work_plans wp
    WHERE wp.id = work_plan_blocks.work_plan_id
      AND (
        wp.created_by = (SELECT auth.uid())
        OR EXISTS (
          SELECT 1
          FROM user_roles ur
          WHERE ur.user_id = (SELECT auth.uid())
            AND ur.role = 'admin'
        )
        OR wp.object_id IN (
          SELECT unnest(pr.object_ids)
          FROM profiles pr
          WHERE pr.id = (SELECT auth.uid())
        )
      )
  )
);

DROP POLICY IF EXISTS "Blocks: insert" ON work_plan_blocks;
CREATE POLICY "Blocks: insert"
ON work_plan_blocks FOR INSERT
TO public
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM work_plans wp
    WHERE wp.id = work_plan_blocks.work_plan_id
      AND (
        wp.created_by = (SELECT auth.uid())
        OR EXISTS (
          SELECT 1
          FROM user_roles ur
          WHERE ur.user_id = (SELECT auth.uid())
            AND ur.role = 'admin'
        )
      )
  )
);

DROP POLICY IF EXISTS "Blocks: update" ON work_plan_blocks;
CREATE POLICY "Blocks: update"
ON work_plan_blocks FOR UPDATE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM work_plans wp
    WHERE wp.id = work_plan_blocks.work_plan_id
      AND (
        wp.created_by = (SELECT auth.uid())
        OR EXISTS (
          SELECT 1
          FROM user_roles ur
          WHERE ur.user_id = (SELECT auth.uid())
            AND ur.role = 'admin'
        )
      )
  )
);

DROP POLICY IF EXISTS "Blocks: delete" ON work_plan_blocks;
CREATE POLICY "Blocks: delete"
ON work_plan_blocks FOR DELETE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM work_plans wp
    WHERE wp.id = work_plan_blocks.work_plan_id
      AND (
        wp.created_by = (SELECT auth.uid())
        OR EXISTS (
          SELECT 1
          FROM user_roles ur
          WHERE ur.user_id = (SELECT auth.uid())
            AND ur.role = 'admin'
        )
      )
  )
);

-- ===================================================================
-- 14. ТАБЛИЦА: work_plan_items
-- ===================================================================

DROP POLICY IF EXISTS "Items: read" ON work_plan_items;
CREATE POLICY "Items: read"
ON work_plan_items FOR SELECT
TO public
USING (
  EXISTS (
    SELECT 1
    FROM work_plan_blocks b
    JOIN work_plans wp ON wp.id = b.work_plan_id
    WHERE b.id = work_plan_items.block_id
      AND (
        wp.created_by = (SELECT auth.uid())
        OR EXISTS (
          SELECT 1
          FROM user_roles ur
          WHERE ur.user_id = (SELECT auth.uid())
            AND ur.role = 'admin'
        )
        OR wp.object_id IN (
          SELECT unnest(pr.object_ids)
          FROM profiles pr
          WHERE pr.id = (SELECT auth.uid())
        )
      )
  )
);

DROP POLICY IF EXISTS "Items: insert" ON work_plan_items;
CREATE POLICY "Items: insert"
ON work_plan_items FOR INSERT
TO public
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM work_plan_blocks b
    JOIN work_plans wp ON wp.id = b.work_plan_id
    WHERE b.id = work_plan_items.block_id
      AND (
        wp.created_by = (SELECT auth.uid())
        OR EXISTS (
          SELECT 1
          FROM user_roles ur
          WHERE ur.user_id = (SELECT auth.uid())
            AND ur.role = 'admin'
        )
      )
  )
);

DROP POLICY IF EXISTS "Items: update" ON work_plan_items;
CREATE POLICY "Items: update"
ON work_plan_items FOR UPDATE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM work_plan_blocks b
    JOIN work_plans wp ON wp.id = b.work_plan_id
    WHERE b.id = work_plan_items.block_id
      AND (
        wp.created_by = (SELECT auth.uid())
        OR EXISTS (
          SELECT 1
          FROM user_roles ur
          WHERE ur.user_id = (SELECT auth.uid())
            AND ur.role = 'admin'
        )
      )
  )
);

DROP POLICY IF EXISTS "Items: delete" ON work_plan_items;
CREATE POLICY "Items: delete"
ON work_plan_items FOR DELETE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM work_plan_blocks b
    JOIN work_plans wp ON wp.id = b.work_plan_id
    WHERE b.id = work_plan_items.block_id
      AND (
        wp.created_by = (SELECT auth.uid())
        OR EXISTS (
          SELECT 1
          FROM user_roles ur
          WHERE ur.user_id = (SELECT auth.uid())
            AND ur.role = 'admin'
        )
      )
  )
);

-- ===================================================================
-- 15. ТАБЛИЦА: business_trip_rates
-- ===================================================================

DROP POLICY IF EXISTS "Users can view business trip rates" ON business_trip_rates;
CREATE POLICY "Users can view business trip rates"
ON business_trip_rates FOR SELECT
TO public
USING ((SELECT auth.role()) = 'authenticated');

DROP POLICY IF EXISTS "Users can insert business trip rates" ON business_trip_rates;
CREATE POLICY "Users can insert business trip rates"
ON business_trip_rates FOR INSERT
TO public
WITH CHECK ((SELECT auth.role()) = 'authenticated');

DROP POLICY IF EXISTS "Users can update business trip rates" ON business_trip_rates;
CREATE POLICY "Users can update business trip rates"
ON business_trip_rates FOR UPDATE
TO public
USING ((SELECT auth.role()) = 'authenticated');

DROP POLICY IF EXISTS "Users can delete business trip rates" ON business_trip_rates;
CREATE POLICY "Users can delete business trip rates"
ON business_trip_rates FOR DELETE
TO public
USING ((SELECT auth.role()) = 'authenticated');

-- ===================================================================
-- 16. ТАБЛИЦА: employee_attendance
-- ===================================================================

DROP POLICY IF EXISTS "Admins can view all attendance records" ON employee_attendance;
CREATE POLICY "Admins can view all attendance records"
ON employee_attendance FOR SELECT
TO public
USING (
  EXISTS (
    SELECT 1
    FROM profiles
    WHERE profiles.id = (SELECT auth.uid())
      AND profiles.role = 'admin'
  )
);

DROP POLICY IF EXISTS "Users can view attendance for their objects" ON employee_attendance;
CREATE POLICY "Users can view attendance for their objects"
ON employee_attendance FOR SELECT
TO public
USING (
  object_id IN (
    SELECT unnest(profiles.object_ids)
    FROM profiles
    WHERE profiles.id = (SELECT auth.uid())
  )
);

DROP POLICY IF EXISTS "Users can view their own attendance" ON employee_attendance;
CREATE POLICY "Users can view their own attendance"
ON employee_attendance FOR SELECT
TO public
USING (
  employee_id IN (
    SELECT e.id
    FROM employees e
    WHERE EXISTS (
      SELECT 1
      FROM profiles p
      WHERE p.id = (SELECT auth.uid())
        AND p.employee_id = e.id
    )
  )
);

DROP POLICY IF EXISTS "Admins and object managers can insert attendance" ON employee_attendance;
CREATE POLICY "Admins and object managers can insert attendance"
ON employee_attendance FOR INSERT
TO public
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM profiles
    WHERE profiles.id = (SELECT auth.uid())
      AND (
        profiles.role = 'admin'
        OR employee_attendance.object_id = ANY(profiles.object_ids)
      )
  )
);

DROP POLICY IF EXISTS "Admins and object managers can update attendance" ON employee_attendance;
CREATE POLICY "Admins and object managers can update attendance"
ON employee_attendance FOR UPDATE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM profiles
    WHERE profiles.id = (SELECT auth.uid())
      AND (
        profiles.role = 'admin'
        OR employee_attendance.object_id = ANY(profiles.object_ids)
      )
  )
);

DROP POLICY IF EXISTS "Only admins can delete attendance" ON employee_attendance;
CREATE POLICY "Only admins can delete attendance"
ON employee_attendance FOR DELETE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM profiles
    WHERE profiles.id = (SELECT auth.uid())
      AND profiles.role = 'admin'
  )
);

-- ===================================================================
-- 17. ТАБЛИЦА: app_versions
-- ===================================================================

DROP POLICY IF EXISTS "Только админы могут изменять верс" ON app_versions;
CREATE POLICY "Только админы могут изменять верс"
ON app_versions FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM profiles
    WHERE profiles.id = (SELECT auth.uid())
      AND profiles.role = 'admin'
  )
);

-- ===================================================================
-- 18. ТАБЛИЦА: materials
-- ===================================================================

DROP POLICY IF EXISTS "materials_update_own" ON materials;
CREATE POLICY "materials_update_own"
ON materials FOR UPDATE
TO authenticated
USING ((SELECT auth.uid()) = created_by)
WITH CHECK ((SELECT auth.uid()) = created_by);

DROP POLICY IF EXISTS "materials_delete_own" ON materials;
CREATE POLICY "materials_delete_own"
ON materials FOR DELETE
TO authenticated
USING ((SELECT auth.uid()) = created_by);

-- ===================================================================
-- ЗАВЕРШЕНИЕ ТРАНЗАКЦИИ
-- ===================================================================

COMMIT;

-- ===================================================================
-- КОНЕЦ МИГРАЦИИ
-- ===================================================================
-- 
-- Результат: все вызовы auth.uid(), auth.role(), auth.jwt() обёрнуты
-- в подзапросы (SELECT ...), что улучшает производительность.
--
-- Безопасность: логика всех политик полностью сохранена.
-- ===================================================================

