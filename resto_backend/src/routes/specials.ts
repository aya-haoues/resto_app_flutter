// routes/specials.ts
import { Hono } from 'hono';
import { supabaseAdmin } from '../index';

const specialsRoute = new Hono();

// GET /specials → Fetch the current daily special and all promotional items
specialsRoute.get('/', async (c) => {
  try {
    // Récupérer le plat du jour
    const { data: dailySpecialData, error: dailyError } = await supabaseAdmin
      .from('menu')
      .select('*')
      .eq('is_daily_special', true)
      .single(); // On s'attend à un seul résultat

    // Récupérer les plats en promotion
    const { data: promotionalItemsData, error: promoError } = await supabaseAdmin
      .from('menu')
      .select('*')
      .eq('is_featured_promotion', true);

    if (dailyError && dailyError.code !== 'PGRST116') { // PGRST116 = "0 rows returned"
      console.error('Erreur Supabase (GET daily special):', dailyError);
      return c.json({ error: dailyError.message }, 500);
    }

    if (promoError) {
      console.error('Erreur Supabase (GET promotional items):', promoError);
      return c.json({ error: promoError.message }, 500);
    }

    return c.json({
      daily_special: dailySpecialData || null,
      promotional_items: promotionalItemsData || [],
    }, 200);
  } catch (err) {
    console.error('Erreur interne (GET specials):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

// PUT /specials/daily → Set a new daily special
specialsRoute.put('/daily', async (c) => {
  const { food_item_id, discounted_price } = await c.req.json();

  if (!food_item_id) {
    return c.json({ error: 'food_item_id is required' }, 400);
  }

  try {
    // Désactiver l'ancien plat du jour
    await supabaseAdmin
      .from('menu')
      .update({ is_daily_special: false, discount_price: null })
      .eq('is_daily_special', true);

    // Activer le nouveau plat du jour
    const { error: updateError } = await supabaseAdmin
      .from('menu')
      .update({
        is_daily_special: true,
        discount_price: discounted_price || null
      })
      .eq('id', food_item_id);

    if (updateError) {
      console.error('Erreur Supabase (SET daily special):', updateError);
      return c.json({ error: updateError.message }, 500);
    }

    return c.json({ success: true, message: 'Plat du jour mis à jour.' }, 200);
  } catch (err) {
    console.error('Erreur interne (SET daily special):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

// PUT /specials/promotional → Add or update a promotional item
specialsRoute.put('/promotional', async (c) => {
  const { food_item_id, original_price, discounted_price } = await c.req.json();

  if (!food_item_id || original_price == null || discounted_price == null) {
    return c.json({ error: 'food_item_id, original_price, and discounted_price are required' }, 400);
  }

  try {
    const { error: updateError } = await supabaseAdmin
      .from('menu')
      .update({
        is_featured_promotion: true,
        original_price: original_price,
        discounted_price: discounted_price
      })
      .eq('id', food_item_id);

    if (updateError) {
      console.error('Erreur Supabase (ADD promotion):', updateError);
      return c.json({ error: updateError.message }, 500);
    }

    return c.json({ success: true, message: 'Promotion ajoutée/mise à jour.' }, 200);
  } catch (err) {
    console.error('Erreur interne (ADD promotion):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

// DELETE /specials/promotional/:id → Remove a promotional item
specialsRoute.delete('/promotional/:id', async (c) => {
  const id = c.req.param('id');

  try {
    const { error: updateError } = await supabaseAdmin
      .from('menu')
      .update({
        is_featured_promotion: false,
        original_price: null,
        discounted_price: null
      })
      .eq('id', id);

    if (updateError) {
      console.error('Erreur Supabase (REMOVE promotion):', updateError);
      return c.json({ error: updateError.message }, 500);
    }

    return c.json({ success: true, message: 'Promotion supprimée.' }, 200);
  } catch (err) {
    console.error('Erreur interne (REMOVE promotion):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

// DELETE /specials/daily → Remove the daily special
specialsRoute.delete('/daily', async (c) => {
  try {
    const { error: updateError } = await supabaseAdmin
      .from('menu')
      .update({
        is_daily_special: false,
        discount_price: null
      })
      .eq('is_daily_special', true);

    if (updateError) {
      console.error('Erreur Supabase (REMOVE daily special):', updateError);
      return c.json({ error: updateError.message }, 500);
    }

    return c.json({ success: true, message: 'Plat du jour supprimé.' }, 200);
  } catch (err) {
    console.error('Erreur interne (REMOVE daily special):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

export { specialsRoute };