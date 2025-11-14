// routes/orders.ts
import { Hono } from 'hono';
import { supabaseAdmin } from '../index'; // Assurez-vous que le chemin est correct

const ordersRoute = new Hono();

// POST /orders → Créer une nouvelle commande
ordersRoute.post('/', async (c) => {
  try {
    const body = await c.req.json();
    const { client_name, table_number, notes, status, created_at } = body;

    // Validation basique
    if (!client_name || !table_number) {
      c.status(400);
      return c.json({ error: 'Les champs client_name, table_number sont requis.' });
    }

    const { data, error } = await supabaseAdmin
      .from('orders') // Remplacez par le nom de votre table Supabase
      .insert([
        {
          client_name: client_name,
          table_number: table_number,
          notes: notes, // <-- Sauvegarder les notes
          status: status || 'pending', // <-- Statut par défaut
          created_at: created_at || new Date().toISOString(),
        }
      ]);

    if (error) {
      console.error('Erreur Supabase (POST orders):', error);
      return c.json({ error: error.message }, 500);
    }

    c.status(201); // Code de succès pour une création
    return c.json({ message: 'Commande créée avec succès', data: data }, 201);
  } catch (err) {
    console.error('Erreur interne (POST orders):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

export { ordersRoute };