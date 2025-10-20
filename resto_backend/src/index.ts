import { createClient } from '@supabase/supabase-js';
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from './schema';
import dotenv from 'dotenv';

// --- Charger les variables d'environnement ---
dotenv.config({ path: './.env' });

console.log('🔍 SUPABASE_DB_URL =', process.env.SUPABASE_DB_URL);

// --- Vérification des variables d'environnement ---
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const DATABASE_URL = process.env.SUPABASE_DB_URL;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || !DATABASE_URL) {
  throw new Error(
    '❌ Vérifiez votre fichier .env : SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY et SUPABASE_DB_URL sont requis.'
  );
}

// --- Client Supabase (administrateur) ---
export const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

// --- Client PostgreSQL via Drizzle ORM ---
const client = postgres(DATABASE_URL, { prepare: false });
export const db = drizzle(client, { schema });

// --- Export du schéma et types ---
export * from './schema';
