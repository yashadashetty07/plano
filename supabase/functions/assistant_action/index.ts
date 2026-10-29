// Supabase Edge Function: assistant_action
// Acts as the trusted boundary between the Flutter Client and n8n / Groq.
// Derives user identity from verified JWT claims. Server secrets stay private.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface RequestPayload {
  prompt: string;
  timezone?: string;
  previewOnly?: boolean;
  confirmedAction?: any;
  idempotencyKey?: string;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 1. Initialize Supabase Auth validator
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    // 2. Validate JWT and get verified user identity
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized: Invalid or expired token" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const payload: RequestPayload = await req.json();
    if (!payload.prompt && !payload.confirmedAction) {
      return new Response(JSON.stringify({ error: "Prompt or confirmed action required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 3. Forward to protected n8n webhook if configured
    const n8nWebhookUrl = Deno.env.get("N8N_WEBHOOK_URL");
    const n8nWebhookSecret = Deno.env.get("N8N_WEBHOOK_SECRET");

    if (!n8nWebhookUrl) {
      // Return structured response indicating unconfigured backend without faking
      return new Response(
        JSON.stringify({
          status: "unconfigured",
          message: "The n8n AI webhook URL (N8N_WEBHOOK_URL) is not configured in Supabase secrets.",
          verifiedUserId: user.id,
          supportedIntents: [
            "log_activity",
            "create_task",
            "checkin_habit",
            "query_summary"
          ],
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const n8nResponse = await fetch(n8nWebhookUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Plano-Webhook-Secret": n8nWebhookSecret || "",
      },
      body: JSON.stringify({
        userId: user.id,
        userEmail: user.email,
        prompt: payload.prompt,
        timezone: payload.timezone || "UTC",
        previewOnly: payload.previewOnly ?? true,
        confirmedAction: payload.confirmedAction || null,
        idempotencyKey: payload.idempotencyKey || null,
      }),
    });

    if (!n8nResponse.ok) {
      const errText = await n8nResponse.text();
      return new Response(
        JSON.stringify({ error: `n8n webhook error: ${n8nResponse.status}`, details: errText }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const result = await n8nResponse.json();
    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: "Internal error in assistant_action", details: err?.message || String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
