-- ============================================================
-- MILENA JOIAS · Setup completo do Supabase
-- Execute no SQL Editor do seu projeto Supabase
-- ============================================================


-- ── 1. TABELA: perfis de usuário (admin ou cliente) ──────────
CREATE TABLE IF NOT EXISTS profiles (
  id      uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  role    text NOT NULL DEFAULT 'cliente',   -- 'admin' ou 'cliente'
  name    text,
  email   text,
  created_at timestamptz DEFAULT now()
);

-- Cria perfil automaticamente a cada novo cadastro
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO profiles (id, email, name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email)
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- RLS na tabela profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "usuario_ve_proprio_perfil"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "admin_ve_todos_perfis"
  ON profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "admin_atualiza_perfis"
  ON profiles FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );


-- ── 2. FUNÇÃO auxiliar ───────────────────────────────────────
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;


-- ── 3. TABELA: pedidos ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
  id            text PRIMARY KEY,
  product       text NOT NULL,
  detail        text,
  qty           integer DEFAULT 1,
  date          text,
  month         text,
  status        text DEFAULT 'recebido',
  ref           text DEFAULT '—',
  client        text,
  obs           text,
  from_client   boolean DEFAULT false,
  files         jsonb DEFAULT '[]',
  photos        jsonb DEFAULT '[]',
  user_id       uuid REFERENCES auth.users,
  client_email  text,
  created_at    timestamptz DEFAULT now()
);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Admin vê e gerencia tudo
CREATE POLICY "admin_select_all_orders"
  ON orders FOR SELECT USING (is_admin());

CREATE POLICY "admin_insert_orders"
  ON orders FOR INSERT WITH CHECK (is_admin());

CREATE POLICY "admin_update_orders"
  ON orders FOR UPDATE USING (is_admin());

CREATE POLICY "admin_delete_orders"
  ON orders FOR DELETE USING (is_admin());

-- Cliente vê só os próprios pedidos
CREATE POLICY "cliente_select_own_orders"
  ON orders FOR SELECT
  USING (NOT is_admin() AND auth.uid() = user_id);

-- Cliente pode criar pedidos
CREATE POLICY "cliente_insert_orders"
  ON orders FOR INSERT
  WITH CHECK (NOT is_admin() AND auth.uid() = user_id);


-- ── 4. STORAGE: buckets para arquivos ────────────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('order-files', 'order-files', false)
ON CONFLICT DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('order-photos', 'order-photos', false)
ON CONFLICT DO NOTHING;

CREATE POLICY "admin_storage_all"
  ON storage.objects FOR ALL
  USING (
    bucket_id IN ('order-files', 'order-photos')
    AND is_admin()
  );

CREATE POLICY "cliente_storage_own"
  ON storage.objects FOR ALL
  USING (
    bucket_id IN ('order-files', 'order-photos')
    AND auth.uid()::text = (storage.foldername(name))[1]
  );


-- ── 5. REALTIME ───────────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE orders;


-- ── FIM ───────────────────────────────────────────────────────
-- PRÓXIMO PASSO (após criar sua conta no sistema):
--
-- Substitua o e-mail abaixo pelo seu e-mail e rode este comando
-- para se tornar admin:
--
-- UPDATE profiles SET role = 'admin'
-- WHERE email = 'seu-email@aqui.com';
