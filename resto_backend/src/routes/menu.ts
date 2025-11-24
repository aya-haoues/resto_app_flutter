// routes/menu.ts
import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { supabaseAdmin } from '../index';

const menuRoute = new Hono();

// Schéma de validation Zod pour un nouvel article
const createItemSchema = z.object({
  name: z.string().min(1),
  category: z.string().min(1),
  price: z.number().positive(),
  description: z.string().optional(),
  image_path: z.string().optional(),
  supplements: z.array(z.string()).optional(), // <--- CHANGÉ : Tableau de chaînes
});

// Schéma de validation Zod pour la mise à jour d'un article
const updateItemSchema = z.object({
  name: z.string().min(1).optional(),
  category: z.string().min(1).optional(),
  price: z.number().positive().optional(),
  description: z.string().optional(),
  image_path: z.string().optional(),
  supplements: z.array(z.string()).optional(), // <--- CHANGÉ : Tableau de chaînes
});

// POST /menu → Créer un nouvel article
menuRoute.post('/', zValidator('json', createItemSchema), async (c) => {
  const body = c.req.valid('json');

  try {
    const { data: newItem, error } = await supabaseAdmin
      .from('menu')
      .insert([{
        name: body.name,
        category: body.category,
        price: body.price,
        description: body.description ?? '',
        image_path: body.image_path ?? 'placeholder.jpg',
        supplements: body.supplements ?? [],
      }])
      .select()
      .single();

    if (error) {
      console.error('Erreur Supabase (POST menu):', error);
      return c.json({ error: error.message }, 500);
    }

    return c.json(newItem, 201);
  } catch (err) {
    console.error('Erreur interne (POST menu):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

// PUT /menu/:id → Mettre à jour un article
menuRoute.put('/:id', zValidator('json', updateItemSchema), async (c) => {
  const id = c.req.param('id');
  const body = c.req.valid('json');

  const updatePayload: any = {};
  if (body.name !== undefined) updatePayload.name = body.name;
  if (body.category !== undefined) updatePayload.category = body.category;
  if (body.price !== undefined) updatePayload.price = body.price;
  if (body.description !== undefined) updatePayload.description = body.description;
  if (body.image_path !== undefined) updatePayload.image_path = body.image_path;
  if (body.supplements !== undefined) updatePayload.supplements = body.supplements;

  try {
    const { error } = await supabaseAdmin
      .from('menu')
      .update(updatePayload)
      .eq('id', id);

    if (error) {
      console.error('Erreur Supabase (PUT menu):', error);
      return c.json({ error: error.message }, 500);
    }

    return c.json({ success: true }, 200);
  } catch (err) {
    console.error('Erreur interne (PUT menu):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

// GET /menu → Récupérer tous les plats
menuRoute.get('/', async (c) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('menu')
      .select('*');

    if (error) {
      console.error('Erreur Supabase (GET menu):', error);
      return c.json({ error: error.message }, 500);
    }

    return c.json(data, 200);
  } catch (err) {
    console.error('Erreur interne (GET menu):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

export { menuRoute };
