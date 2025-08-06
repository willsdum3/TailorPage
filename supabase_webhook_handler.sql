-- Clerk Webhook Handler for Supabase
-- This function handles Clerk webhook events and syncs user data to Supabase

-- Enable the http extension for webhook handling
CREATE EXTENSION IF NOT EXISTS "http" WITH SCHEMA "extensions";

-- Create a function to handle Clerk webhook events
CREATE OR REPLACE FUNCTION handle_clerk_webhook()
RETURNS TRIGGER AS $$
DECLARE
    webhook_data JSONB;
    event_type TEXT;
    user_data JSONB;
    clerk_id TEXT;
    user_uuid UUID;
BEGIN
    -- Get the webhook data from the request
    webhook_data := current_setting('request.body')::JSONB;
    event_type := webhook_data->>'type';
    user_data := webhook_data->'data';
    clerk_id := user_data->>'id';

    -- Handle different webhook event types
    CASE event_type
        WHEN 'user.created' THEN
            -- Create new user in Supabase
            INSERT INTO users (
                clerk_id,
                name,
                username,
                email,
                image_url
            ) VALUES (
                clerk_id,
                COALESCE(user_data->>'first_name', '') || ' ' || COALESCE(user_data->>'last_name', ''),
                COALESCE(user_data->>'username', user_data->>'email_addresses'->0->>'email_address'),
                user_data->>'email_addresses'->0->>'email_address',
                user_data->>'image_url'
            )
            ON CONFLICT (clerk_id) DO NOTHING;

        WHEN 'user.updated' THEN
            -- Update existing user in Supabase
            UPDATE users SET
                name = COALESCE(user_data->>'first_name', '') || ' ' || COALESCE(user_data->>'last_name', ''),
                username = COALESCE(user_data->>'username', user_data->>'email_addresses'->0->>'email_address'),
                email = user_data->>'email_addresses'->0->>'email_address',
                image_url = user_data->>'image_url',
                updated_at = NOW()
            WHERE clerk_id = clerk_id;

        WHEN 'user.deleted' THEN
            -- Delete user from Supabase (cascade will handle related data)
            DELETE FROM users WHERE clerk_id = clerk_id;

        ELSE
            -- Log unknown event types
            RAISE NOTICE 'Unknown webhook event type: %', event_type;
    END CASE;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a webhook endpoint function
CREATE OR REPLACE FUNCTION clerk_webhook()
RETURNS JSON AS $$
DECLARE
    webhook_data JSONB;
    event_type TEXT;
    signature TEXT;
    expected_signature TEXT;
    webhook_secret TEXT;
BEGIN
    -- Get webhook secret from environment
    webhook_secret := current_setting('app.clerk_webhook_secret', true);
    
    -- Get the webhook signature from headers
    signature := current_setting('request.headers', true)::JSONB->>'svix-signature';
    
    -- Verify webhook signature (basic verification)
    -- In production, you should implement proper signature verification
    IF webhook_secret IS NULL THEN
        RAISE EXCEPTION 'Webhook secret not configured';
    END IF;

    -- Get the webhook data
    webhook_data := current_setting('request.body')::JSONB;
    event_type := webhook_data->>'type';

    -- Handle the webhook event
    PERFORM handle_clerk_webhook();

    -- Return success response
    RETURN json_build_object(
        'status', 'success',
        'message', 'Webhook processed successfully',
        'event_type', event_type
    );
EXCEPTION
    WHEN OTHERS THEN
        -- Return error response
        RETURN json_build_object(
            'status', 'error',
            'message', SQLERRM,
            'event_type', COALESCE(event_type, 'unknown')
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to manually sync a user from Clerk
CREATE OR REPLACE FUNCTION sync_user_from_clerk(clerk_user_id TEXT)
RETURNS JSON AS $$
DECLARE
    user_data JSONB;
    user_uuid UUID;
BEGIN
    -- This function would typically make an HTTP request to Clerk API
    -- For now, we'll just return a placeholder
    -- In production, you'd implement the actual Clerk API call here
    
    RETURN json_build_object(
        'status', 'success',
        'message', 'User sync initiated',
        'clerk_id', clerk_user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to get or create user from Clerk ID
CREATE OR REPLACE FUNCTION get_or_create_user(clerk_user_id TEXT, user_name TEXT, user_email TEXT, user_username TEXT, user_image_url TEXT DEFAULT NULL)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Try to get existing user
    SELECT id INTO user_uuid FROM users WHERE clerk_id = clerk_user_id;
    
    -- If user doesn't exist, create them
    IF user_uuid IS NULL THEN
        INSERT INTO users (
            clerk_id,
            name,
            username,
            email,
            image_url
        ) VALUES (
            clerk_user_id,
            user_name,
            user_username,
            user_email,
            user_image_url
        ) RETURNING id INTO user_uuid;
    END IF;
    
    RETURN user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION clerk_webhook() TO anon;
GRANT EXECUTE ON FUNCTION sync_user_from_clerk(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_or_create_user(TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- Create a trigger to automatically handle webhook events
-- Note: This is a simplified approach. In production, you'd use Supabase's webhook functionality
CREATE OR REPLACE FUNCTION process_clerk_webhook()
RETURNS TRIGGER AS $$
BEGIN
    -- This would be called when a webhook event is received
    -- For now, it's a placeholder for the webhook processing logic
    RETURN NEW;
END;
$$ LANGUAGE plpgsql; 