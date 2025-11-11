import { Hono } from "hono";
import { serve } from "@hono/node-server";
import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";
import { cors } from "hono/cors";
import { logger } from 'hono/logger';
import { commandesRoute } from "./routes/commandes"; // ✅ Chemin correct ?
import { menuRoute } from './routes/menu';
dotenv.config({ path: "./.env" });

// 1. Initialisation Supabase (Globale)
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

// Ajoutez une vérification pour éviter les erreurs si les clés sont manquantes
if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error("❌ ERREUR : Les variables SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY sont manquantes dans le fichier .env.");
  process.exit(1); // Arrête le serveur
}

export const supabaseAdmin = createClient(
    SUPABASE_URL!,
    SUPABASE_SERVICE_ROLE_KEY!,
    {
      auth: { persistSession: false },
    }
);

// NOTE: Si vous utilisez Drizzle, votre objet 'db' doit être initialisé
// dans un fichier séparé (ex: db.ts) qui importe supabaseAdmin.

const app = new Hono();

// 2. Middleware d'Erreur (Très utile en dev)
app.onError((err, c) => {
  console.error('Erreur Hono:', err.message);
  return c.text('Erreur serveur interne', 500);
});

// 3. Middleware Logger (pour voir si la requête arrive)
app.use('*', logger());

// 4. Middleware CORS (pour autoriser Flutter)
app.use(
  '*',
  cors({
    origin: ['http://localhost:3000', 'http://10.0.2.2:8081', 'http://10.0.2.2:8082'],
    allowHeaders: ['Content-Type'],
    allowMethods: ['GET', 'POST', 'DELETE'],
  })
);
// ✅ Route test de base
app.get("/", (c) => c.text("🚀 Backend Resto connecté avec succès !"));

// ✅ Routes principales
app.route("/commandes", commandesRoute);

app.route("/menu", menuRoute);

// ⚠️ COMMENTEZ CETTE LIGNE - elle ne fonctionnera que si clientsRoute est importé
// app.route("/clients", clientsRoute);

// ✅ Démarrage du serveur
const PORT = Number(process.env.PORT) || 8081;

serve({
  fetch: app.fetch,
  port: PORT,
  hostname: "0.0.0.0", // IMPORTANT : Permet l'accès depuis l'émulateur (10.0.2.2)
});

console.log(`✅ Serveur Hono en ligne sur http://localhost:${PORT}`);

// ✅ Vérification automatique de la connexion Supabase
async function testSupabaseConnection() {
  const { data, error } = await supabaseAdmin
    .from("commandes")
    .select("*")
    .limit(1);

  if (error) {
    console.error("❌ Supabase non connecté :", error.message);
  } else {
    console.log("✅ Supabase connecté, exemple de commande :", data);
  }
}

testSupabaseConnection();
