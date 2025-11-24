// routes/client_order.ts
import { Hono } from 'hono';
import { supabaseAdmin } from '../index';

const clientOrderRoute = new Hono();

// GET /client-order?client_name=...&table_number=...
clientOrderRoute.get('/', async (c) => {
  const clientName = c.req.query('client_name');
  const tableNumberStr = c.req.query('table_number');
  const tableNumber = parseInt(tableNumberStr);

  // Valider les paramètres
  if (!clientName || isNaN(tableNumber)) {
    c.status(400);
    return c.json({ error: 'client_name et table_number sont requis.' });
  }

  try {
    // Rechercher la commande la plus récente pour ce client et cette table
    const { data, error } = await supabaseAdmin
      .from('commandes')
      .select(`
        *,
        commande_items (
          food_name,
          price,
          quantity
        )
      `)
      .eq('client_name', clientName)
      .eq('table_number', tableNumber)
      .order('created_at', { ascending: false })
      .limit(1)
      .single(); // Récupérer un seul résultat

    if (error) {
      // Si aucune commande n'est trouvée, Supabase retourne une erreur
      if (error.code === 'PGRST116') { // Code d'erreur Supabase pour "aucun résultat"
        c.status(404); // Retourner 404 si la commande n'existe pas
        return c.json({ error: 'Aucune commande active trouvée pour ce client et cette table.' });
      }
      console.error('Error in /client-order:', error.message);
      c.status(500);
      return c.json({ error: 'Internal Server Error' });
    }

    // Si une commande est trouvée, la retourner
    return c.json(data);
  } catch (error: any) {
    console.error('Error in /client-order:', error.message);
    c.status(500);
    return c.json({ error: 'Internal Server Error' });
  }
});

export { clientOrderRoute };