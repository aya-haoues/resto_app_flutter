// routes/commandes.ts
import { Hono } from 'hono';
import { supabaseAdmin } from '../index';

const commandesRoute = new Hono();

// POST /commandes → Créer une nouvelle commande
commandesRoute.post('/', async (c) => {
  try {
    console.log('📥 Requête POST reçue sur /commandes');
    let body;
    try {
      const contentType = c.req.header('Content-Type');
      if (!contentType || !contentType.includes('application/json')) {
        console.log('❌ Content-Type non JSON:', contentType);
        c.status(400);
        return c.json({ message: 'Content-Type doit être application/json' });
      }
      body = await c.req.json();
      console.log('📦 Données reçues:', JSON.stringify(body, null, 2));
    } catch (parseError: any) {
      console.error('❌ Erreur de parsing JSON:', parseError.message);
      c.status(400);
      return c.json({ message: 'Erreur de parsing JSON: ' + parseError.message });
    }

    const { client_name, total_price, items, table_number, notes, client_id } = body;

    if (!total_price || typeof total_price !== 'number' || !items || items.length === 0) {
      console.log('❌ Validation échouée:', { total_price, items });
      c.status(400);
      return c.json({ message: 'Données de commande incomplètes ou mal formées.' });
    }

    // --- 1. Insérer dans 'orders' (SANS le statut) ---
    const { data: orderData, error: orderError } = await supabaseAdmin
      .from('orders')
      .insert({
        client_name: client_name || 'Client sur place',
        table_number: table_number,
        notes: notes,
      })
      .select('id')
      .single();

    if (orderError) {
      console.error('❌ Erreur Supabase (Table orders):', orderError.message);
      c.status(500);
      return c.json({ message: `Erreur 'orders': ${orderError.message}` });
    }

    const orderId = orderData.id;
    console.log('✅ ID orders:', orderId);

    // --- 2. Insérer dans 'commandes' (AVEC le statut) ---
    // Only include client_id if it was provided in the request
    const commandeDataToInsert: any = {
      order_id: orderId,
      client_name: client_name || 'Client sur place',
      total_price: total_price,
      table_number: table_number,
      notes: notes,
      status: 'pending',
    };

    // Add client_id only if it exists
    if (client_id !== undefined && client_id !== null) {
      commandeDataToInsert.client_id = client_id;
    }

    const { data: commandeData, error: commandeError } = await supabaseAdmin
      .from('commandes')
      .insert(commandeDataToInsert)
      .select('id')
      .single();

    if (commandeError) {
      console.error('❌ Erreur Supabase (Table commandes):', commandeError.message);
      c.status(500);
      return c.json({ message: `Erreur 'commandes': ${commandeError.message}` });
    }

    const commandeId = commandeData.id;
    console.log('✅ ID commandes:', commandeId);

    // --- 3. Insérer les articles ---
    const commandeItemsToInsert = items.map((item: any) => ({
      commande_id: commandeId,
      food_name: item.name,
      price: item.price,
      quantity: item.quantity || 1,
    }));

    const { error: itemsError } = await supabaseAdmin
      .from('commande_items')
      .insert(commandeItemsToInsert);

    if (itemsError) {
      console.error('❌ Erreur (commande_items):', itemsError.message);
      c.status(500);
      return c.json({ message: `Erreur articles: ${itemsError.message}` });
    }

    // --- 4. Mettre à jour la table ---
    if (table_number != null) {
      const { error: tableError } = await supabaseAdmin
        .from('tables')
        .update({
          status: 'occupied',
          order_summary: `${items.length} plat(s) pour ${client_name || 'Client'}`,
          time_occupied: new Date().toISOString(),
        })
        .eq('number', table_number);

      if (tableError) {
        console.warn('⚠️ Erreur mise à jour table (non bloquante):', tableError.message);
      } else {
        console.log(`✅ Table ${table_number} marquée comme occupée.`);
      }
    }

    // --- 5. Réponse de succès ---
    console.log('✅ Commande enregistrée avec succès !');
    return c.json({
      message: 'Commande enregistrée avec succès',
      order_id: orderId,
      commande_id: commandeId,
      status: 'pending',
    }, 200);

  } catch (error: any) {
    console.error('❌ Erreur serveur interne:', error.message);
    c.status(500);
    return c.json({ message: 'Erreur interne du serveur.' });
  }
});
// PUT /commandes/:id/status → Mettre à jour le statut
commandesRoute.put('/:id/status', async (c) => {
  const id = c.req.param('id');
  const { status } = await c.req.json();

  const validStatuses = ['pending', 'in_progress', 'done'];
  if (!validStatuses.includes(status)) {
    c.status(400);
    return c.json({ error: 'Statut invalide. Utilisez: pending, in_progress, done.' });
  }

  const { error } = await supabaseAdmin
    .from('commandes')
    .update({ status })
    .eq('id', id);

  if (error) {
    console.error('❌ Erreur mise à jour statut:', error.message);
    return c.json({ error: error.message }, 500);
  }

  // ✅ Si le statut est 'done', libérer automatiquement la table
  if (status === 'done') {
    const { data: commande } = await supabaseAdmin
      .from('commandes')
      .select('table_number')
      .eq('id', id)
      .single();

    if (commande?.table_number) {
      const { error: tableError } = await supabaseAdmin
        .from('tables')
        .update({
          status: 'free',
          order_summary: null,
          time_occupied: null,
        })
        .eq('number', commande.table_number);

      if (tableError) {
        console.warn('⚠️ Impossible de libérer la table:', tableError.message);
      } else {
        console.log(`✅ Table ${commande.table_number} libérée automatiquement.`);
      }
    }
  }

  return c.json({ success: true, status }, 200);
});

// GET /commandes → Récupérer TOUTES les commandes avec leurs items
commandesRoute.get('/', async (c) => {
  try {
    // Utiliser une requête SQL complexe pour joindre les tables
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
      .order('created_at', { ascending: false });

    if (error) {
      console.error('❌ Erreur Supabase (GET /commandes):', error.message);
      return c.json({ error: error.message }, 500);
    }

    // Transformer les données pour que `items` soit un tableau d'objets
    const formattedData = data.map((row: any) => {
      return {
        ...row,
        items: row.commande_items || [], // Si aucun item, retourner un tableau vide
      };
    });

    return c.json(formattedData, 200);
  } catch (err) {
    console.error('❌ Erreur interne (GET /commandes):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});
export { commandesRoute };