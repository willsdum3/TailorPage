import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://beatfpwyqbhkihxsyqxx.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJlYXRmcHd5cWJoa2loeHN5cXh4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMzNjIyOTcsImV4cCI6MjA2ODkzODI5N30.q_ywwbu_OYYSYpd9a_rCkgzg13kocfzXXdk9TcuGQzQ';

export const supabase = createClient(supabaseUrl, supabaseAnonKey); 