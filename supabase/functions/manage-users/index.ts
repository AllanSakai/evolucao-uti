import { createClient } from "npm:@supabase/supabase-js@2.57.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

const requiredEnv = (name: string) => {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Variável ${name} não configurada.`);
  return value;
};

const normalizedPrivilegedEmails = () =>
  new Set(
    requiredEnv("PRIVILEGED_EMAILS")
      .split(/[,;]/)
      .map((email) => email.trim().toLowerCase())
      .filter(Boolean),
  );

const cleanText = (value: unknown) =>
  typeof value === "string" ? value.trim() : "";

const validEmail = (email: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ message: "Método não permitido." }, 405);

  try {
    const authorization = request.headers.get("Authorization");
    if (!authorization) return json({ message: "Sessão não informada." }, 401);

    const supabaseUrl = requiredEnv("SUPABASE_URL");
    const anonKey = requiredEnv("SUPABASE_ANON_KEY");
    const serviceRoleKey = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");
    const callerClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: callerData, error: callerError } = await callerClient.auth.getUser();
    const caller = callerData.user;
    if (callerError || !caller?.email) {
      return json({ message: "Sessão inválida ou expirada." }, 401);
    }
    if (!normalizedPrivilegedEmails().has(caller.email.toLowerCase())) {
      return json({ message: "Sua conta não tem permissão para gerenciar usuários." }, 403);
    }

    const body = await request.json() as Record<string, unknown>;
    const action = cleanText(body.action);
    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    if (action === "list") {
      const users = [];
      let page = 1;
      const perPage = 200;
      while (true) {
        const { data, error } = await admin.auth.admin.listUsers({ page, perPage });
        if (error) throw error;
        users.push(...data.users);
        if (data.users.length < perPage) break;
        page += 1;
      }
      return json({
        users: users.map((user) => ({
          id: user.id,
          email: user.email ?? "",
          name: cleanText(user.user_metadata?.name),
          created_at: user.created_at,
          last_sign_in_at: user.last_sign_in_at,
        })),
      });
    }

    const id = cleanText(body.id);
    if (action === "delete") {
      if (!id) return json({ message: "Usuário não informado." }, 400);
      if (id === caller.id) {
        return json({ message: "Você não pode apagar a conta que está conectada." }, 400);
      }
      const { error } = await admin.auth.admin.deleteUser(id);
      if (error) throw error;
      return json({ success: true });
    }

    if (action !== "create" && action !== "update") {
      return json({ message: "Operação inválida." }, 400);
    }

    const name = cleanText(body.name);
    const email = cleanText(body.email).toLowerCase();
    const password = typeof body.password === "string" ? body.password : "";
    if (name.length < 3) return json({ message: "Informe o nome completo." }, 400);
    if (!validEmail(email)) return json({ message: "Informe um e-mail válido." }, 400);
    if (action === "create" && password.length < 8) {
      return json({ message: "A senha deve ter pelo menos 8 caracteres." }, 400);
    }
    if (password && password.length < 8) {
      return json({ message: "A senha deve ter pelo menos 8 caracteres." }, 400);
    }

    if (action === "create") {
      const { error } = await admin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { name },
      });
      if (error) throw error;
      return json({ success: true }, 201);
    }

    if (!id) return json({ message: "Usuário não informado." }, 400);
    const attributes: {
      email: string;
      user_metadata: { name: string };
      password?: string;
    } = { email, user_metadata: { name } };
    if (password) attributes.password = password;
    const { error } = await admin.auth.admin.updateUserById(id, attributes);
    if (error) throw error;
    return json({ success: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Erro interno.";
    const duplicate = message.toLowerCase().includes("already") ||
      message.toLowerCase().includes("registered") ||
      message.toLowerCase().includes("exists");
    return json(
      { message: duplicate ? "Já existe um usuário com este e-mail." : message },
      duplicate ? 409 : 500,
    );
  }
});
