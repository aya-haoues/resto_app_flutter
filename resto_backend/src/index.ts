// index.ts
import { Hono } from "hono";
import { serve } from "@hono/node-server";
import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";
import { cors } from "hono/cors";
import { logger } from 'hono/logger';
import { commandesRoute } from "./routes/commandes";
import { menuRoute } from './routes/menu';
import { categoriesRoute } from './routes/categories';
import { tablesRoute } from './routes/tables';
import { ordersRoute } from './routes/orders'; // 👈 IMPORT NEW ROUTE
import { clientOrderRoute } from './routes/client_order';
import { checkTableRoute } from './routes/check_table';
import { commandesWithItemsRoute } from './routes/commandes_with_items'; // 👈 AJOUTER CETTE LIGNE
dotenv.config({ path: "./.env" });

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error("❌ ERREUR : Les variables SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY sont manquantes dans le fichier .env.");
  process.exit(1);
}

export const supabaseAdmin = createClient(
  SUPABASE_URL!,
  SUPABASE_SERVICE_ROLE_KEY!,
  {
    auth: { persistSession: false },
  }
);

const app = new Hono();

app.onError((err, c) => {
  console.error('Erreur Hono:', err.message);
  return c.text('Erreur serveur interne', 500);
});

app.use('*', logger());

app.use(
  '*',
  cors({
    origin: ['http://localhost:3000', 'http://10.0.2.2:8081', 'http://10.0.2.2:8082' , 'http://192.168.56.1:8082' ],
    allowHeaders: ['Content-Type'],
    allowMethods: ['GET', 'POST', 'PUT', 'DELETE'],
  })
);

app.get("/", (c) => c.text("🚀 Backend Resto connecté avec succès !"));

app.route("/commandes", commandesRoute);
app.route("/menu", menuRoute);
app.route("/categories", categoriesRoute);
app.route("/tables", tablesRoute);
app.route('/orders', ordersRoute);
app.route('/client-order', clientOrderRoute);
app.route('/check-table', checkTableRoute);
app.route('/commandes_with_items', commandesWithItemsRoute); // 👈 AJOUTER CETTE LIGNE
const PORT = Number(process.env.PORT) || 8082;

serve({
  fetch: app.fetch,
  port: PORT,
  hostname: "0.0.0.0",
});

console.log(`✅ Serveur Hono en ligne sur http://localhost:${PORT}`);

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