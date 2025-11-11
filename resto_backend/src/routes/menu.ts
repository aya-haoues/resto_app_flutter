// routes/menu.ts
import { Hono } from 'hono';
import { supabaseAdmin } from '../index';

const menuRoute = new Hono();

// GET /menu → Fetch all menu items
menuRoute.get('/', async (c) => {
  const { data, error } = await supabaseAdmin.from('menu').select('*').order('category');
  if (error) return c.json({ error: error.message }, 500);
  return c.json(data, 200);
});

// POST /menu → Add new item
menuRoute.post('/', async (c) => {
  const body = await c.req.json();
  const { name, category, price, description, image_path } = body;
  if (!name || !category || price == null) return c.json({ error: 'Missing fields' }, 400);

  const { data, error } = await supabaseAdmin.from('menu').insert({
    name,
    category,
    price: parseFloat(price),
    description: description || '',
    image_path: image_path || 'placeholder.jpg',
  }).select();

  if (error) return c.json({ error: error.message }, 500);
  return c.json(data[0], 201);
});

// PUT /menu/:id → Update existing item
menuRoute.put('/:id', async (c) => {
  const id = c.req.param('id');
  const body = await c.req.json();
  const { name, category, price, description, image_path } = body;

  if (!name || !category || price == null) {
    return c.json({ error: 'Missing required fields' }, 400);
  }

  const { error } = await supabaseAdmin
    .from('menu')
    .update({
      name,
      category,
      price: parseFloat(price),
      description: description || '',
      image_path: image_path || 'placeholder.jpg',
    })
    .eq('id', id);

  if (error) return c.json({ error: error.message }, 500);
  return c.json({ success: true }, 200);
});

// DELETE /menu/:id → Delete item
menuRoute.delete('/:id', async (c) => {
  const id = c.req.param('id');
  const { error } = await supabaseAdmin.from('menu').delete().eq('id', id);
  if (error) return c.json({ error: error.message }, 500);
  return c.json({ success: true }, 200);
});

export { menuRoute };