// routes/supplements.ts
import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { supabaseAdmin } from '../index';

const supplementsRoute = new Hono();

// Schéma de validation
const supplementSchema = z.object({
  name: z.string().min(1),
  price: z.number().nonnegative(), // Prix doit être >= 0
});

// GET /supplements → Récupérer tous les suppléments
supplementsRoute.get('/', async (c) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('supplements')
      .select('*')
      .order('name', { ascending: true });

    if (error) {
      console.error('Erreur Supabase (GET supplements):', error);
      return c.json({ error: error.message }, 500);
    }

    return c.json(data, 200);
  } catch (err) {
    console.error('Erreur interne (GET supplements):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

// POST /supplements → Créer un nouveau supplément
supplementsRoute.post('/', zValidator('json', supplementSchema), async (c) => {
  const body = c.req.valid('json');

  try {
    const { data, error } = await supabaseAdmin
      .from('supplements')
      .insert([{ name: body.name, price: body.price }])
      .select()
      .single();

    if (error) {
      console.error('Erreur Supabase (POST supplement):', error);
      return c.json({ error: error.message }, 500);
    }

    return c.json(data, 201);
  } catch (err) {
    console.error('Erreur interne (POST supplement):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

// PUT /supplements/:id → Mettre à jour un supplément
supplementsRoute.put('/:id', zValidator('json', supplementSchema), async (c) => {
  const id = c.req.param('id');
  const body = c.req.valid('json');

  try {
    const { data, error } = await supabaseAdmin
      .from('supplements')
      .update({ name: body.name, price: body.price })
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('Erreur Supabase (PUT supplement):', error);
      return c.json({ error: error.message }, 500);
    }

    return c.json(data, 200);
  } catch (err) {
    console.error('Erreur interne (PUT supplement):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

// DELETE /supplements/:id → Supprimer un supplément
supplementsRoute.delete('/:id', async (c) => {
  const id = c.req.param('id');

  try {
    const { error } = await supabaseAdmin
      .from('supplements')
      .delete()
      .eq('id', id);

    if (error) {
      console.error('Erreur Supabase (DELETE supplement):', error);
      return c.json({ error: error.message }, 500);
    }

    return c.json({ success: true }, 200);
  } catch (err) {
    console.error('Erreur interne (DELETE supplement):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

export { supplementsRoute };