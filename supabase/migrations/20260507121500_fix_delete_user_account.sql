-- Fix delete_user_account to remove dependent profile data first

CREATE OR REPLACE FUNCTION public.delete_user_account() RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM public.profiles WHERE id = auth.uid();
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;
