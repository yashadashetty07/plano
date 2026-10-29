-- Keep the signup trigger available to Supabase Auth without exposing its
-- SECURITY DEFINER privileges through the public API.
REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO supabase_auth_admin;
