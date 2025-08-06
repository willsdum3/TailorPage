# Supabase + Clerk Integration Setup Guide

This guide will walk you through setting up Supabase with Clerk authentication for your Tailor Page App.

## Prerequisites

- A Supabase project
- A Clerk application
- Your React app with Clerk already configured

## Step 1: Set up Supabase Project

1. **Create a new Supabase project** at [supabase.com](https://supabase.com)
2. **Get your project credentials**:
   - Go to Settings → API
   - Copy your Project URL and anon/public key

## Step 2: Configure Environment Variables

1. **Create a `.env` file** in your project root (if it doesn't exist)
2. **Add the following environment variables**:

```env
# Supabase Configuration
REACT_APP_SUPABASE_URL=your_supabase_project_url
REACT_APP_SUPABASE_ANON_KEY=your_supabase_anon_key

# Clerk Configuration (you should already have these)
REACT_APP_CLERK_PUBLISHABLE_KEY=your_clerk_publishable_key
REACT_APP_CLERK_SECRET_KEY=your_clerk_secret_key

# Clerk Webhook Secret (for Supabase webhook verification)
CLERK_WEBHOOK_SECRET=your_clerk_webhook_secret
```

## Step 3: Set up Database Schema

1. **Open your Supabase dashboard**
2. **Go to SQL Editor**
3. **Run the database schema** from `database_schema.sql`:
   - Copy the contents of `database_schema.sql`
   - Paste it into the SQL Editor
   - Click "Run" to create all tables and functions

4. **Run the quiz schema** from `quiz_results_schema.sql`:
   - Copy the contents of `quiz_results_schema.sql`
   - Paste it into the SQL Editor
   - Click "Run" to create quiz-related tables

5. **Run the webhook handler** from `supabase_webhook_handler.sql`:
   - Copy the contents of `supabase_webhook_handler.sql`
   - Paste it into the SQL Editor
   - Click "Run" to create webhook functions

## Step 4: Configure Clerk Webhooks

1. **Go to your Clerk Dashboard**
2. **Navigate to Webhooks**
3. **Create a new webhook endpoint**:
   - **Endpoint URL**: `https://your-project-ref.supabase.co/functions/v1/clerk-webhook`
   - **Events to send**: Select all user-related events:
     - `user.created`
     - `user.updated`
     - `user.deleted`
4. **Copy the webhook signing secret** and add it to your environment variables

## Step 5: Set up Supabase Edge Functions (Optional)

For production, you should create a Supabase Edge Function to handle Clerk webhooks:

1. **Install Supabase CLI**:
   ```bash
   npm install -g supabase
   ```

2. **Initialize Supabase in your project**:
   ```bash
   supabase init
   ```

3. **Create a webhook function**:
   ```bash
   supabase functions new clerk-webhook
   ```

4. **Add the webhook handler code** to `supabase/functions/clerk-webhook/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    )

    const { type, data } = await req.json()
    const clerkId = data.id

    switch (type) {
      case 'user.created':
        await supabaseClient
          .from('users')
          .insert({
            clerk_id: clerkId,
            name: `${data.first_name || ''} ${data.last_name || ''}`.trim(),
            username: data.username || data.email_addresses?.[0]?.email_address?.split('@')[0],
            email: data.email_addresses?.[0]?.email_address,
            image_url: data.image_url,
          })
        break

      case 'user.updated':
        await supabaseClient
          .from('users')
          .update({
            name: `${data.first_name || ''} ${data.last_name || ''}`.trim(),
            username: data.username || data.email_addresses?.[0]?.email_address?.split('@')[0],
            email: data.email_addresses?.[0]?.email_address,
            image_url: data.image_url,
            updated_at: new Date().toISOString(),
          })
          .eq('clerk_id', clerkId)
        break

      case 'user.deleted':
        await supabaseClient
          .from('users')
          .delete()
          .eq('clerk_id', clerkId)
        break
    }

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
```

5. **Deploy the function**:
   ```bash
   supabase functions deploy clerk-webhook
   ```

## Step 6: Test the Integration

1. **Start your development server**:
   ```bash
   npm start
   ```

2. **Sign up/sign in with Clerk** - this should automatically create a user in Supabase

3. **Check your Supabase dashboard**:
   - Go to Table Editor
   - Check the `users` table to see if your user was created

4. **Test user synchronization**:
   - Update your profile in Clerk
   - Check if the changes are reflected in Supabase

## Step 7: Update Your App to Use Supabase

The integration is now set up! Your app will automatically:

- **Sync users** from Clerk to Supabase when they sign up/sign in
- **Store favorites** in Supabase using the helper functions
- **Track quiz results** and personality profiles
- **Maintain data consistency** between Clerk and Supabase

## Troubleshooting

### Common Issues:

1. **Environment variables not loading**:
   - Make sure your `.env` file is in the project root
   - Restart your development server after adding environment variables

2. **Database connection errors**:
   - Verify your Supabase URL and anon key are correct
   - Check that you've run all the SQL schema files

3. **Webhook not working**:
   - Verify the webhook URL is correct
   - Check the webhook signing secret
   - Look at the Supabase logs for errors

4. **RLS (Row Level Security) errors**:
   - Make sure you're authenticated with Clerk
   - Check that the user exists in the Supabase `users` table

### Debugging:

1. **Check browser console** for any JavaScript errors
2. **Check Supabase logs** in the dashboard
3. **Check Clerk webhook logs** in the Clerk dashboard
4. **Use the Supabase client helper functions** to debug database operations

## Next Steps

Once the integration is working:

1. **Test the favorites functionality** using the helper functions
2. **Implement quiz result storage** using the quiz schema
3. **Add reading lists and activity tracking**
4. **Set up production environment variables**
5. **Deploy your app with the new Supabase integration**

## Security Notes

- **Never expose your Supabase service role key** in the frontend
- **Use RLS policies** to secure your data
- **Verify webhook signatures** in production
- **Keep your environment variables secure**

## Support

If you encounter issues:

1. Check the [Supabase documentation](https://supabase.com/docs)
2. Check the [Clerk documentation](https://clerk.com/docs)
3. Review the error logs in both dashboards
4. Test with a fresh user account to isolate issues 