# Plano n8n Assistant Workflow

The workflow at `n8n/workflows/plano_assistant_workflow.json` accepts requests only from the Edge Function using n8n Webhook Header Auth, calls Groq to produce a structured preview, and validates the response before returning it. It does not write to the database.

After an n8n instance is available:

1. Import the workflow JSON.
2. On **Webhook: Receive Request**, set Authentication to **Header Auth** and create/select a credential with header name `X-Plano-Webhook-Secret` and a high-entropy secret value. This keeps the shared secret in n8n's encrypted credential store rather than in a workflow expression or source file.
3. Create an n8n Groq credential and select it on **Groq Chat Model**. Enter `GROQ_API_KEY` only in the n8n credential UI.
4. Activate the workflow and copy its production webhook URL.
5. Add `N8N_WEBHOOK_URL` and `N8N_WEBHOOK_SECRET` under **Supabase Dashboard → Edge Functions → Secrets**. Set `N8N_WEBHOOK_SECRET` to the same value used in the n8n Header Auth credential.

The Flutter user must review and confirm every write. The Edge Function then validates the action, writes through the signed-in user's JWT and RLS, and reads the row back before returning `execution_status: executed`. No Supabase secret key is used for these user-scoped writes. Do not report the assistant operational until n8n, Groq, the Edge Function, and an end-to-end persisted action have all been verified.
