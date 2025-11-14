// routes/tables.ts
import { Hono } from 'hono';
import { supabaseAdmin } from '../index'; // Assurez-vous que le chemin est correct

const tablesRoute = new Hono();


// GET /tables → Fetch all table statuses
tablesRoute.get('/', async (c) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('tables') // Nom de votre table Supabase
      .select('*') // Sélectionne toutes les colonnes, y compris 'order_summary'
      .order('number'); // Triez par 'number' pour une présentation cohérente

    if (error) {
      console.error('Erreur Supabase (GET tables):', error);
      return c.json({ error: error.message }, 500);
    }

    return c.json(data, 200);
  } catch (err) {
    console.error('Erreur interne (GET tables):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

// routes/tables.ts
 // PUT /tables/:id → Update table status AND notes
 tablesRoute.put('/:id', async (c) => {
   const id = c.req.param('id');
   const body = await c.req.json();
   const { status, notes } = body; // <--- EXTRAIRE LE CHAMP 'notes'

   if (!status || (status !== 'free' && status !== 'occupied')) {
      console.log('❌ Statut non valide reçu:', status);
      c.status(400);
      return c.json({ error: 'Statut invalide. Utilisez "free" ou "occupied".' });
   }

   const tableNumber = parseInt(id);
   if (isNaN(tableNumber)) {
     c.status(400);
     return c.json({ error: 'Le numéro de table doit être un entier.' });
   }

   const { error } = await supabaseAdmin
     .from('tables') // Nom de votre table Supabase
     .update({
       status: status,
       notes: notes // <--- SAUVEGARDER LE CHAMP 'notes'
     })
     .eq('number', tableNumber); // <--- Utiliser 'number' pour trouver la ligne à mettre à jour

   if (error) {
     console.error('Erreur Supabase (PUT table):', error);
     return c.json({ error: error.message }, 500);
   }

   return c.json({ success: true }, 200);
 });


export { tablesRoute };