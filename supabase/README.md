# Supabase Edge Functions Setup

This directory contains Supabase Edge Functions for the Get A Job application.

## Functions

### generate-cover-letter

Proxies OpenAI API requests to keep the API key secure on the server side.

## Deployment

1. Install Supabase CLI:
```bash
npm install -g supabase
```

2. Login to Supabase:
```bash
supabase login
```

3. Link to your project:
```bash
supabase link --project-ref YOUR_PROJECT_REF
```

4. Set the OpenAI API key as a secret:
```bash
supabase secrets set OPENAI_API_KEY=your-openai-api-key-here
```

5. Deploy the function:
```bash
supabase functions deploy generate-cover-letter
```

## Testing Locally

1. Start Supabase locally:
```bash
supabase start
```

2. Serve the function:
```bash
supabase functions serve generate-cover-letter --env-file ./supabase/.env.local
```

3. Create `.env.local` with:
```
OPENAI_API_KEY=your-openai-api-key-here
```

## Usage

The function is called automatically by the Flutter app when generating cover letters.

Endpoint: `https://YOUR_PROJECT.supabase.co/functions/v1/generate-cover-letter`
