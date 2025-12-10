-- Enable access for authenticated users to procurement tables

-- procurement_applications
create policy "Enable all access for authenticated users"
on "public"."procurement_applications"
as permissive
for all
to authenticated
using (true)
with check (true);

-- procurement_requests
create policy "Enable all access for authenticated users"
on "public"."procurement_requests"
as permissive
for all
to authenticated
using (true)
with check (true);

-- procurement_history
create policy "Enable all access for authenticated users"
on "public"."procurement_history"
as permissive
for all
to authenticated
using (true)
with check (true);

