// routes/orders.ts
import { Hono } from 'hono';
import { supabaseAdmin } from '../index';

const ordersRoute = new Hono();

// GET /orders/:id -> Get a single order by ID
ordersRoute.get('/:id', async (c) => {
  const id = c.req.param('id');

  try {
    const { data, error } = await supabaseAdmin
      .from('orders')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      console.error('❌ Erreur Supabase (GET order):', error.message);
      c.status(500);
      return c.json({ error: error.message });
    }

    return c.json(data, 200);
  } catch (err) {
    console.error('❌ Erreur interne (GET order):', err);
    c.status(500);
    return c.json({ error: 'Erreur interne du serveur' });
  }
});

// PUT /orders/:id/status -> Update the status of an order
ordersRoute.put('/:id/status', async (c) => {
  const id = c.req.param('id');
  const body = await c.req.json();
  const { status } = body;

  // Validate status
  const validStatuses = ['pending', 'in_progress', 'done'];
  if (!validStatuses.includes(status)) {
    c.status(400);
    return c.json({ error: 'Statut invalide. Utilisez "pending", "in_progress", ou "done".' });
  }

  try {
    const { error } = await supabaseAdmin
      .from('orders')
      .update({ status: status })
      .eq('id', id);

    if (error) {
      console.error('❌ Erreur Supabase (PUT order status):', error.message);
      c.status(500);
      return c.json({ error: error.message });
    }

    // Optional: If status is 'done', update the table to 'free'
    if (status === 'done') {
      const { data: orderData } = await supabaseAdmin
        .from('orders')
        .select('table_number')
        .eq('id', id)
        .single();

      if (orderData?.table_number) {
        const { error: tableError } = await supabaseAdmin
          .from('tables')
          .update({ status: 'free', order_summary: null, time_occupied: null })
          .eq('number', orderData.table_number);

        if (tableError) {
          console.error('❌ Erreur lors de la libération de la table:', tableError.message);
          // Log but don't fail the main request
        }
      }
    }

    return c.json({ success: true, updatedStatus: status }, 200);
  } catch (err) {
    console.error('❌ Erreur interne (PUT order status):', err);
    c.status(500);
    return c.json({ error: 'Erreur interne du serveur' });
  }
});

export { ordersRoute };