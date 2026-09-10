/**
 * Public environment values for the Next.js app.
 * Secrets must never be placed in `NEXT_PUBLIC_*` variables.
 */
export const env = {
  supabaseUrl: process.env.NEXT_PUBLIC_SUPABASE_URL ?? "",
  supabasePublishableKey:
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ??
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ??
    "",
} as const;

/**
 * Returns true when Supabase public credentials are present.
 */
export function isSupabaseConfigured(): boolean {
  return Boolean(env.supabaseUrl && env.supabasePublishableKey);
}
