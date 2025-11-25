// routes/commandes.ts
import { Hono } from 'hono';
import { supabaseAdmin } from '../index';

const commandesRoute = new Hono();

// POST /commandes → Créer une nouvelle commande
commandesRoute.post('/', async (c) => {
  try {
    const body = await c.req.json();
    const { client_name, total_price, items, table_number, notes, client_id } = body;

    if (!total_price || typeof total_price !== 'number' || !items || items.length === 0) {
      return c.json({ message: 'Données de commande incomplètes ou mal formées.' }, 400);
    }

    // 1️⃣ Créer l'ordre
    const { data: orderData, error: orderError } = await supabaseAdmin
      .from('orders')
      .insert({ client_name: client_name || 'Client sur place', table_number, notes })
      .select('id')
      .single();

    if (orderError) return c.json({ message: orderError.message }, 500);
    const orderId = orderData.id;

    // 2️⃣ Créer la commande principale
    const commandeDataToInsert: any = {
      order_id: orderId,
      client_name: client_name || 'Client sur place',
      total_price,
      table_number,
      notes,
      status: 'pending',
    };
    if (client_id) commandeDataToInsert.client_id = client_id;

    const { data: commandeData, error: commandeError } = await supabaseAdmin
      .from('commandes')
      .insert(commandeDataToInsert)
      .select('id')
      .single();

    if (commandeError) return c.json({ message: commandeError.message }, 500);
    const commandeId = commandeData.id;

    // 3️⃣ Ajouter les items avec suppléments
    const commandeItemsToInsert = items.map((item: any) => ({
      commande_id: commandeId,
      food_name: item.name,
      price: item.price,
      quantity: item.quantity || 1,
      image_path: item.image_path || 'placeholder.jpg',
      supplements: item.supplements || [], // <-- SUPPLÉMENTS
    }));

    const { error: itemsError } = await supabaseAdmin
      .from('commande_items')
      .insert(commandeItemsToInsert);

    if (itemsError) return c.json({ message: itemsError.message }, 500);

    // 4️⃣ Mettre à jour la table si nécessaire
    if (table_number != null) {
      await supabaseAdmin
        .from('tables')
        .update({
          status: 'occupied',
          order_summary: `${items.length} plat(s) pour ${client_name || 'Client'}`,
          time_occupied: new Date().toISOString(),
        })
        .eq('number', table_number);
    }

    return c.json({
      message: 'Commande enregistrée avec succès',
      order_id: orderId,
      commande_id: commandeId,
      status: 'pending',
    }, 200);

  } catch (error: any) {
    return c.json({ message: 'Erreur interne du serveur: ' + error.message }, 500);
  }
});

// routes/commandes.ts

// PUT /commandes/:id/status → Mettre à jour le statut
commandesRoute.put('/:id/status', async (c) => {
  const id = c.req.param('id');
  const { status } = await c.req.json();
  const validStatuses = ['pending', 'in_progress', 'done'];
  if (!validStatuses.includes(status)) return c.json({ error: 'Statut invalide.' }, 400);

  const { error } = await supabaseAdmin
    .from('commandes')
    .update({ status })
    .eq('id', id);

  if (error) return c.json({ error: error.message }, 500);

  // ⚠️ NE PAS LIBÉRER LA TABLE ICI ⚠️
  // La libération sera faite par une autre route dédiée.

  return c.json({ success: true, status }, 200);
});


// GET /commandes → Récupérer toutes les commandes avec items et suppléments
commandesRoute.get('/', async (c) => {
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

    if (error) return c.json({ error: error.message }, 500);

    const formattedData = data.map((row: any) => ({
      ...row,
      items: row.commande_items?.map((item: any) => ({
        ...item,
        supplements: item.supplements || [],
      })) || [],
    }));

    return c.json(formattedData, 200);

  } catch (err) {
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

export { commandesRoute };
