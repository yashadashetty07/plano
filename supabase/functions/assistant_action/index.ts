import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

const categories = new Set([
  "work", "personal_project", "learning", "workout", "habit", "admin", "creative", "rest", "custom",
]);
const intents = new Set(["log_activity", "create_task", "checkin_habit", "query_summary", "clarify_question"]);
type JsonObject = Record<string, unknown>;

function response(body: JsonObject, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

function validDate(value: unknown): value is string {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const parsed = new Date(`${value}T00:00:00Z`);
  return !Number.isNaN(parsed.valueOf()) && parsed.toISOString().slice(0, 10) === value;
}

function validateAction(value: unknown): { action?: JsonObject; error?: string } {
  if (!value || typeof value !== "object" || Array.isArray(value)) return { error: "Action must be an object." };
  const action = value as JsonObject;
  if (Object.keys(action).some((key) => !["id", "intent", "parameters", "clarification_question"].includes(key))) return { error: "Action contains unsupported fields." };
  if (typeof action.id !== "string" || !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(action.id)) {
    return { error: "Action id must be a UUID idempotency key." };
  }
  if (typeof action.intent !== "string" || !intents.has(action.intent)) return { error: "Unsupported action intent." };
  const p = action.parameters;
  if (!p || typeof p !== "object" || Array.isArray(p)) return { error: "Action parameters must be an object." };
  const params = p as JsonObject;
  const allowedParams: Record<string, string[]> = {
    log_activity: ["title", "category", "duration_minutes", "date", "notes", "timezone"],
    create_task: ["title", "priority", "due_date", "category", "estimated_minutes"],
    checkin_habit: ["habit_name", "checkin_date"],
    query_summary: ["date_range", "category_filter", "topic"],
    clarify_question: [],
  };
  if (Object.keys(params).some((key) => !allowedParams[String(action.intent)].includes(key))) return { error: "Action contains unsupported parameter fields." };
  if (action.intent === "log_activity") {
    if (typeof params.title !== "string" || !params.title.trim() || params.title.length > 300) return { error: "Activity title is required (max 300 characters)." };
    if (typeof params.category !== "string" || !categories.has(params.category)) return { error: "Activity category is invalid." };
    if (typeof params.duration_minutes !== "number" || !Number.isInteger(params.duration_minutes) || params.duration_minutes < 1 || params.duration_minutes > 1440) return { error: "Activity duration must be 1–1440 minutes." };
    if (!validDate(params.date)) return { error: "Activity date must be YYYY-MM-DD." };
    if (params.timezone != null) {
      if (typeof params.timezone !== "string" || params.timezone.length > 100) return { error: "Activity timezone is invalid." };
      try { new Intl.DateTimeFormat("en", { timeZone: params.timezone }); } catch { return { error: "Activity timezone is invalid." }; }
    }
  }
  if (action.intent === "create_task") {
    if (typeof params.title !== "string" || !params.title.trim() || params.title.length > 300) return { error: "Task title is required (max 300 characters)." };
    if (typeof params.priority !== "string" || !["low", "medium", "high", "urgent"].includes(params.priority)) return { error: "Task priority is invalid." };
    if (params.due_date != null && !validDate(params.due_date)) return { error: "Task due date must be YYYY-MM-DD or null." };
    if (params.category != null && (typeof params.category !== "string" || !categories.has(params.category))) return { error: "Task category is invalid." };
    if (params.estimated_minutes != null && (typeof params.estimated_minutes !== "number" || !Number.isInteger(params.estimated_minutes) || params.estimated_minutes < 0 || params.estimated_minutes > 100000)) return { error: "Estimated minutes are invalid." };
  }
  if (action.intent === "checkin_habit") {
    if (typeof params.habit_name !== "string" || !params.habit_name.trim() || params.habit_name.length > 200) return { error: "Habit name is required." };
    if (!validDate(params.checkin_date)) return { error: "Check-in date must be YYYY-MM-DD." };
  }
  if (action.intent === "query_summary") {
    if (params.date_range != null && !["today", "week", "month", "custom"].includes(String(params.date_range))) return { error: "Report date range is invalid." };
    if (params.category_filter != null && params.category_filter !== "all" && (typeof params.category_filter !== "string" || !categories.has(params.category_filter))) return { error: "Report category is invalid." };
    if (params.topic != null && (typeof params.topic !== "string" || params.topic.length > 300)) return { error: "Report topic is invalid." };
  }
  if (action.intent === "clarify_question" && (typeof action.clarification_question !== "string" || !action.clarification_question.trim() || action.clarification_question.length > 500)) return { error: "Clarification question is required." };
  return { action };
}

function sameValue(row: JsonObject | null, expected: JsonObject): boolean {
  return !!row && Object.entries(expected).every(([key, value]) => row[key] === value);
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return response({ error: "Method not allowed." }, 405);

  const authorization = req.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) return response({ error: "Authentication required." }, 401);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  let publicKey = Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? Deno.env.get("SUPABASE_ANON_KEY");
  if (!publicKey) {
    try {
      const keys = JSON.parse(Deno.env.get("SUPABASE_PUBLISHABLE_KEYS") ?? "{}");
      publicKey = typeof keys.default === "string" ? keys.default : undefined;
    } catch {
      return response({ error: "Supabase publishable key configuration is invalid." }, 503);
    }
  }
  if (!supabaseUrl || !publicKey) return response({ error: "Supabase function configuration is incomplete." }, 503);

  const db = createClient(supabaseUrl, publicKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: { user }, error: authError } = await db.auth.getUser();
  if (authError || !user) return response({ error: "Invalid or expired access token." }, 401);

  let payload: JsonObject;
  try {
    const parsed: unknown = await req.json();
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return response({ error: "Request body must be an object." }, 400);
    payload = parsed as JsonObject;
  } catch {
    return response({ error: "Request body must be valid JSON." }, 400);
  }

  if (payload.confirmedAction != null) {
    const validation = validateAction(payload.confirmedAction);
    if (!validation.action) return response({ error: validation.error ?? "Invalid action." }, 400);
    const action = validation.action;
    const p = action.parameters as JsonObject;
    let table: string;
    let expected: JsonObject;
    let result: JsonObject | null = null;

    if (action.intent === "log_activity") {
      table = "activity_logs";
      expected = {
        id: action.id,
        user_id: user.id,
        title: p.title,
        category: p.category,
        duration_minutes: p.duration_minutes,
        date: p.date,
        timezone: typeof p.timezone === "string" ? p.timezone : "UTC",
        source: "assistant",
        idempotency_key: action.id,
      };
      const { error } = await db.from(table).upsert(expected, { onConflict: "id", ignoreDuplicates: true });
      if (error) return response({ error: "Activity was not saved.", details: error.message }, 500);
      const { data, error: readError } = await db.from(table).select(Object.keys(expected).join(",")).eq("id", action.id).eq("user_id", user.id).maybeSingle();
      if (readError || !sameValue(data as JsonObject | null, expected)) return response({ error: "Activity write could not be verified." }, 500);
      result = data as JsonObject;
    } else if (action.intent === "create_task") {
      table = "tasks";
      expected = {
        id: action.id,
        user_id: user.id,
        title: p.title,
        status: "todo",
        priority: p.priority,
        due_date: p.due_date ?? null,
        category: p.category ?? "work",
        estimated_minutes: p.estimated_minutes ?? 0,
      };
      const { error } = await db.from(table).upsert(expected, { onConflict: "id", ignoreDuplicates: true });
      if (error) return response({ error: "Task was not saved.", details: error.message }, 500);
      const { data, error: readError } = await db.from(table).select(Object.keys(expected).join(",")).eq("id", action.id).eq("user_id", user.id).maybeSingle();
      if (readError || !sameValue(data as JsonObject | null, expected)) return response({ error: "Task write could not be verified." }, 500);
      result = data as JsonObject;
    } else if (action.intent === "checkin_habit") {
      const { data: habits, error: habitError } = await db.from("habits").select("id,name").eq("user_id", user.id).ilike("name", String(p.habit_name).trim());
      if (habitError) return response({ error: "Could not find the requested habit." }, 500);
      if (!habits || habits.length !== 1) return response({ error: habits?.length ? "More than one habit matches; clarify the habit name." : "No matching habit exists." }, 409);
      table = "habit_checkins";
      expected = { habit_id: habits[0].id, user_id: user.id, checkin_date: p.checkin_date };
      const { error } = await db.from(table).upsert(expected, { onConflict: "habit_id,checkin_date", ignoreDuplicates: true });
      if (error) return response({ error: "Habit check-in was not saved.", details: error.message }, 500);
      const { data, error: readError } = await db.from(table).select("habit_id,user_id,checkin_date").eq("habit_id", String(habits[0].id)).eq("checkin_date", String(p.checkin_date)).eq("user_id", user.id).maybeSingle();
      if (readError || !sameValue(data as JsonObject | null, expected)) return response({ error: "Habit check-in write could not be verified." }, 500);
      result = data as JsonObject;
    } else {
      return response({ error: "Only activity, task, and habit-check-in writes are supported." }, 400);
    }

    return response({ status: "success", execution_status: "executed", intent: action.intent, verified: true, record: result });
  }

  if (typeof payload.prompt !== "string" || !payload.prompt.trim() || payload.prompt.length > 4000) {
    return response({ error: "Prompt is required and must be at most 4000 characters." }, 400);
  }

  const webhookUrl = Deno.env.get("N8N_WEBHOOK_URL");
  const webhookSecret = Deno.env.get("N8N_WEBHOOK_SECRET");
  if (!webhookUrl || !webhookSecret) return response({ error: "Assistant is not configured: n8n webhook secrets are missing." }, 503);

  try {
    const upstream = await fetch(webhookUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Plano-Webhook-Secret": webhookSecret },
      body: JSON.stringify({
        prompt: payload.prompt,
        timezone: typeof payload.timezone === "string" ? payload.timezone : "UTC",
        idempotencyKey: typeof payload.idempotencyKey === "string" ? payload.idempotencyKey : crypto.randomUUID(),
      }),
      signal: AbortSignal.timeout(20000),
    });
    if (!upstream.ok) return response({ error: "Assistant provider request failed.", upstreamStatus: upstream.status }, 502);
    const output: unknown = await upstream.json();
    if (!output || typeof output !== "object" || Array.isArray(output)) return response({ error: "Assistant returned an invalid response." }, 502);
    const action = output as JsonObject;
    if (typeof action.intent !== "string" || !intents.has(action.intent) || !action.parameters || typeof action.parameters !== "object" || Array.isArray(action.parameters)) {
      return response({ error: "Assistant response failed schema validation." }, 502);
    }
    const idempotencyKey = typeof payload.idempotencyKey === "string" ? payload.idempotencyKey : null;
    if (!idempotencyKey || !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(idempotencyKey)) return response({ error: "A valid idempotency key is required." }, 400);
    const validation = validateAction({ id: idempotencyKey, intent: action.intent, parameters: action.parameters, clarification_question: action.clarification_question });
    if (!validation.action) return response({ error: "Assistant response failed action validation.", details: validation.error }, 502);
    const parameters = { ...(action.parameters as JsonObject) };
    if (action.intent === "log_activity" && parameters.timezone == null) {
      const requestedTimezone = typeof payload.timezone === "string" ? payload.timezone : "UTC";
      try {
        new Intl.DateTimeFormat("en", { timeZone: requestedTimezone });
        parameters.timezone = requestedTimezone;
      } catch {
        return response({ error: "Timezone is invalid." }, 400);
      }
    }
    const preview = {
      id: idempotencyKey,
      user_prompt: payload.prompt,
      intent: action.intent,
      parameters,
      is_destructive: action.is_destructive === true,
      requires_confirmation: action.intent === "log_activity" || action.intent === "create_task" || action.intent === "checkin_habit",
      clarification_question: typeof action.clarification_question === "string" ? action.clarification_question : null,
      summary: typeof action.summary === "string" ? action.summary : "Review the parsed request.",
      execution_status: "preview",
      timestamp: new Date().toISOString(),
    };
    return response(preview);
  } catch {
    return response({ error: "Assistant provider is unavailable." }, 502);
  }
});
