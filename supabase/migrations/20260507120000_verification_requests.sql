-- Verification requests policies and acceptance notification

DROP POLICY IF EXISTS "Users can view their verification requests" ON public.verification_requests;
CREATE POLICY "Users can view their verification requests"
  ON public.verification_requests
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create verification requests" ON public.verification_requests;
CREATE POLICY "Users can create verification requests"
  ON public.verification_requests
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their verification requests" ON public.verification_requests;
CREATE POLICY "Users can delete their verification requests"
  ON public.verification_requests
  FOR DELETE
  USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.handle_verification_update() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF (NEW.status = 'accepted') THEN
    UPDATE public.profiles
    SET is_verified = true
    WHERE id = NEW.user_id;

    IF (OLD.status IS DISTINCT FROM NEW.status) THEN
      INSERT INTO public.notifications (receiver_id, sender_id, type)
      VALUES (NEW.user_id, NEW.user_id, 'verification');
    END IF;
  ELSE
    UPDATE public.profiles
    SET is_verified = false
    WHERE id = NEW.user_id;
  END IF;

  RETURN NEW;
END;
$$;
