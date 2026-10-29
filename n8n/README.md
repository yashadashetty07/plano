# Plano n8n Automation & AI Workflow Guide

## 1. Overview
The Plano AI assistant uses n8n as the orchestration engine between the trusted Supabase Edge Function and Groq LLM inference (`llama-3.3-70b-versatile`).

## 2. Request Security Flow
1. **Flutter App** authenticated with Supabase sends prompt to `assistant_action` Edge Function.
2. **Supabase Edge Function** validates JWT, derives user ID from claims, and signs request with `X-Plano-Webhook-Secret`.
3. **n8n Webhook** verifies the secret header.
4. **Groq Model Node** parses the text into typed structured JSON.
5. Destructive actions (deletions, bulk updates) return `requires_confirmation: true` for user preview before applying.
6. The client requires explicit user approval before sending `confirmedAction`.

## 3. Deployment Steps
1. In your n8n instance, go to **Workflows > Import from File** and select `plano_assistant_workflow.json`.
2. Configure **Groq API Credentials**:
   - Provide your Groq API Key.
3. Configure Environment Variables in n8n:
   - `PLANO_WEBHOOK_SECRET`: A high-entropy random secret matching `N8N_WEBHOOK_SECRET` in Supabase Edge Function secrets.
4. Activate the workflow and copy the production webhook URL into your Supabase Edge Function secrets:
   ```bash
   supabase secrets set N8N_WEBHOOK_URL="https://your-n8n.example.com/webhook/plano-assistant"
   supabase secrets set N8N_WEBHOOK_SECRET="your-high-entropy-secret"
   ```
