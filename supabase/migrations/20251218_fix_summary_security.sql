-- Fix security definer issue causing infinite loader and data leak
-- Switch functions to SECURITY INVOKER to respect RLS policies

ALTER FUNCTION get_months_summary() SECURITY INVOKER;
ALTER FUNCTION get_month_employees_summary(DATE) SECURITY INVOKER;
ALTER FUNCTION get_month_hours_summary(DATE) SECURITY INVOKER;
ALTER FUNCTION get_month_objects_summary(DATE) SECURITY INVOKER;
ALTER FUNCTION get_month_systems_summary(DATE) SECURITY INVOKER;

