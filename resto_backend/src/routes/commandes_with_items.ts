// routes/commandes_with_items.ts
import { Hono } from 'hono';
import { supabaseAdmin } from '../index';

const commandesWithItemsRoute = new Hono();

// GET /commandes_with_items → Fetch all orders with their items
commandesWithItemsRoute.get('/', async (c) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('commandes_with_items')
      .select('*')
      .order('created_at', { ascending: false });
    if (error) {
      console.error('❌ Erreur Supabase (GET commandes_with_items):', error.message);
      return c.json({ error: error.message }, 500);
    }
    return c.json(data, 200);
  } catch (err) {
    console.error('❌ Erreur interne (GET commandes_with_items):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

export { commandesWithItemsRoute };