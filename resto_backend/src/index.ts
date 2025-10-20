// src/index.ts

// 1. Ajoutez les imports nécessaires
import { Hono } from 'hono';
import { serve } from '@hono/node-server';
import { createClient } from '@supabase/supabase-js'; // Importez le client Supabase
import dotenv from 'dotenv';
import clientsApp from './routes/clients'; // Ce fichier doit être 'tables' si vous suivez l'exemple précédent
import tablesApp from './routes/clients'; // <--- Si vous NE POUVEZ PAS renommer le fichier
dotenv.config({ path: './.env' });

// 2. Initialisez le client Supabase Admin
// Assurez-vous que ces variables sont définies dans votre fichier .env
const SUPABASE_URL = process.env.SUPABASE_URL!;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY!; // Clé Service Role (admin)

const supabaseAdmin = createClient(
  SUPABASE_URL,
  SUPABASE_SERVICE_KEY,
  {
    auth: {
      persistSession: false, // Important pour le backend/service
    }
  }
);
const app = new Hono();

// Monte le router clients sur /clients
app.route('/clients', clientsApp);
app.route('/api/table', tablesApp);
// Test serveur
app.get('/', (c) => c.text('Backend UP!'));

const PORT = parseInt(process.env.PORT || '8080', 10);

// Démarrage du serveur - CORRECTION ICI
serve(
    {
        fetch: app.fetch, // Passez l'application Hono (app) via sa méthode fetch
        port: PORT,      // Port défini
        hostname: '0.0.0.0' // Hostname
    },
    // Vous n'avez pas besoin d'un second argument de type callback ici.
);


// --- Test de connexion Supabase ---
async function testSupabaseConnection() {
  const { data, error } = await supabaseAdmin
    .from('clients')
    .select('*')
    .limit(1);

  if (error) {
    console.error('❌ Supabase non connecté ou erreur:', error);
  } else {
    console.log('✅ Supabase connecté ! Exemple de donnée:', data);
  }
}

testSupabaseConnection(); // Appel de la fonction

