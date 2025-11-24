// routes/check_table.ts
import { Hono } from 'hono';
import { supabaseAdmin } from '../index';

const checkTableRoute = new Hono();

checkTableRoute.get('/:number', async (c) => {
  const number = parseInt(c.req.param('number'));
  if (isNaN(number)) {
    c.status(400);
    return c.json({ error: 'Le numéro de table doit être un entier.' });
  }

  try {
    const { data, error } = await supabaseAdmin
      .from('tables')
      .select('status')
      .eq('number', number)
      .single();

    if (error) throw error;
    return c.json({ status: data.status });
  } catch (error: any) {
    console.error('Erreur dans /check-table:', error.message);
    c.status(500);
    return c.json({ error: 'Erreur serveur' });
  }
});

export { checkTableRoute };