// routes/tables.ts
import { Hono } from 'hono';
import { supabaseAdmin } from '../index';

const tablesRoute = new Hono();

// GET /tables → Fetch all table statuses
tablesRoute.get('/', async (c) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('tables')
      .select('*')
      .order('number');

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

// GET /tables/:number → Fetch a single table by its number
tablesRoute.get('/:number', async (c) => {
  const number = parseInt(c.req.param('number'));
  if (isNaN(number)) {
    c.status(400);
    return c.json({ error: 'Le numéro de table doit être un entier.' });
  }

  try {
    const { data, error } = await supabaseAdmin
      .from('tables')
      .select('*')
      .eq('number', number)
      .single();

    if (error) {
      console.error('Erreur Supabase (GET table by number):', error);
      c.status(500);
      return c.json({ error: error.message });
    }

    return c.json(data, 200);
  } catch (err) {
    console.error('Erreur interne (GET table by number):', err);
    c.status(500);
    return c.json({ error: 'Erreur interne du serveur' });
  }
});

// PUT /tables/:id → Update table status AND notes
tablesRoute.put('/:id', async (c) => {
  const id = c.req.param('id');
  const body = await c.req.json();
  const { status, notes } = body;

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
    .from('tables')
    .update({
      status: status,
      notes: notes,
    })
    .eq('number', tableNumber);

  if (error) {
    console.error('Erreur Supabase (PUT table):', error);
    return c.json({ error: error.message }, 500);
  }

  return c.json({ success: true }, 200);
});

export { tablesRoute };