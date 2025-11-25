// routes/commandes_with_items.ts
import { Hono } from 'hono';
import { supabaseAdmin } from '../index';

const commandesWithItemsRoute = new Hono();

// GET /commandes_with_items → Fetch all orders with their items
commandesWithItemsRoute.get('/', async (c) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('commandes')
      .select(`
        *,
        commande_items (
          food_name,
          price,
          quantity,
          image_path,
          supplements
        )
      `)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('❌ Erreur Supabase (GET commandes_with_items):', error.message);
      return c.json({ error: error.message }, 500);
    }

    // Transformer les données pour que `items` soit un tableau d'objets
    const formattedData = data.map((row: any) => {
      return {
        ...row,
        items: row.commande_items || [], // Si aucun item, retourne un tableau vide
      };
    });

    return c.json(formattedData, 200);
  } catch (err) {
    console.error('❌ Erreur interne (GET commandes_with_items):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

export { commandesWithItemsRoute };