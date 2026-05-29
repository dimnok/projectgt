-- Одноразовые приглашения в компанию (выдаёт owner/admin).

CREATE TABLE public.company_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  code TEXT NOT NULL,
  created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role_id UUID REFERENCES public.roles(id) ON DELETE SET NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ,
  used_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT company_invitations_code_unique UNIQUE (code),
  CONSTRAINT company_invitations_code_format CHECK (code ~ '^[A-Z2-9]{8}$')
);

CREATE INDEX company_invitations_company_id_idx ON public.company_invitations(company_id);
CREATE INDEX company_invitations_active_code_idx ON public.company_invitations(code)
  WHERE used_at IS NULL AND revoked_at IS NULL;

COMMENT ON TABLE public.company_invitations IS
  'Одноразовые коды приглашения в компанию.';

ALTER TABLE public.company_invitations ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.is_company_manager(
  p_company_id UUID,
  p_user_id UUID DEFAULT auth.uid()
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.company_members cm
    WHERE cm.company_id = p_company_id
      AND cm.user_id = p_user_id
      AND cm.is_active = true
      AND (
        cm.is_owner = true
        OR cm.system_role IN ('owner', 'admin')
      )
  );
$$;

CREATE POLICY "Managers can view company invitations"
  ON public.company_invitations
  FOR SELECT
  TO authenticated
  USING (public.is_company_manager(company_id));

CREATE OR REPLACE FUNCTION public.generate_invitation_code()
RETURNS TEXT
LANGUAGE plpgsql
VOLATILE
AS $$
DECLARE
  v_chars CONSTANT TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_result TEXT := '';
  v_i INT;
BEGIN
  FOR v_i IN 1..8 LOOP
    v_result := v_result || substr(
      v_chars,
      1 + floor(random() * length(v_chars))::INT,
      1
    );
  END LOOP;
  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_company_invitation(
  p_company_id UUID,
  p_expires_in_days INT DEFAULT 7
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_code TEXT;
  v_attempts INT := 0;
  v_expires_at TIMESTAMPTZ;
  v_row public.company_invitations%ROWTYPE;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  IF NOT public.is_company_manager(p_company_id, v_user_id) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_expires_in_days IS NULL OR p_expires_in_days < 1 OR p_expires_in_days > 90 THEN
    RAISE EXCEPTION 'invalid_expiry';
  END IF;

  v_expires_at := now() + make_interval(days => p_expires_in_days);

  LOOP
    v_attempts := v_attempts + 1;
    IF v_attempts > 20 THEN
      RAISE EXCEPTION 'code_generation_failed';
    END IF;

    v_code := public.generate_invitation_code();

    BEGIN
      INSERT INTO public.company_invitations (
        company_id,
        code,
        created_by,
        expires_at
      )
      VALUES (
        p_company_id,
        v_code,
        v_user_id,
        v_expires_at
      )
      RETURNING * INTO v_row;
      EXIT;
    EXCEPTION
      WHEN unique_violation THEN
        NULL;
    END;
  END LOOP;

  RETURN jsonb_build_object(
    'id', v_row.id,
    'code', v_row.code,
    'expires_at', v_row.expires_at,
    'created_at', v_row.created_at
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.revoke_company_invitation(p_invitation_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_company_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  SELECT company_id INTO v_company_id
  FROM public.company_invitations
  WHERE id = p_invitation_id;

  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'invitation_not_found';
  END IF;

  IF NOT public.is_company_manager(v_company_id, v_user_id) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  UPDATE public.company_invitations
  SET revoked_at = now()
  WHERE id = p_invitation_id
    AND used_at IS NULL
    AND revoked_at IS NULL;
END;
$$;

CREATE OR REPLACE FUNCTION public.redeem_company_invitation(p_code TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_code TEXT;
  v_inv public.company_invitations%ROWTYPE;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  v_code := upper(trim(coalesce(p_code, '')));
  IF v_code = '' OR length(v_code) <> 8 THEN
    RAISE EXCEPTION 'invalid_code';
  END IF;

  SELECT * INTO v_inv
  FROM public.company_invitations
  WHERE code = v_code
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invitation_not_found';
  END IF;

  IF v_inv.used_at IS NOT NULL THEN
    RAISE EXCEPTION 'invitation_already_used';
  END IF;

  IF v_inv.revoked_at IS NOT NULL THEN
    RAISE EXCEPTION 'invitation_revoked';
  END IF;

  IF v_inv.expires_at <= now() THEN
    RAISE EXCEPTION 'invitation_expired';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.company_members cm
    WHERE cm.company_id = v_inv.company_id
      AND cm.user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'already_member';
  END IF;

  INSERT INTO public.company_members (
    company_id,
    user_id,
    is_owner,
    role_id,
    is_active
  )
  VALUES (
    v_inv.company_id,
    v_user_id,
    false,
    v_inv.role_id,
    true
  );

  UPDATE public.profiles
  SET last_company_id = v_inv.company_id,
      updated_at = now()
  WHERE id = v_user_id;

  UPDATE public.company_invitations
  SET used_at = now(),
      used_by = v_user_id
  WHERE id = v_inv.id;

  RETURN v_inv.company_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.is_company_manager(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_company_invitation(UUID, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.revoke_company_invitation(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.redeem_company_invitation(TEXT) TO authenticated;
