// routes/categories.ts
import { Hono } from 'hono';
import { supabaseAdmin } from '../index'; // Assurez-vous que le chemin est correct

const categoriesRoute = new Hono();

// GET /categories → Fetch all categories
categoriesRoute.get('/', async (c) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('categories')
      .select('*')
      .order('name'); // Trie par nom

    if (error) {
      console.error('Erreur Supabase (GET categories):', error);
      return c.json({ error: error.message }, 500);
    }

    return c.json(data, 200);
  } catch (err) {
    console.error('Erreur interne (GET categories):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

// POST /categories → Add a new category
categoriesRoute.post('/', async (c) => {
  try {
    const body = await c.req.json();
    const { name } = body;

    if (!name || typeof name !== 'string' || name.trim() === '') {
      return c.json({ error: 'Le nom de la catégorie est requis et doit être une chaîne non vide.' }, 400);
    }

    const trimmedName = name.trim();

    // Vérifier si une catégorie avec ce nom existe déjà
    const { data: existingData, error: existingError } = await supabaseAdmin
      .from('categories')
      .select('id')
      .eq('name', trimmedName)
      .single();

    if (existingData) {
      return c.json({ error: 'Une catégorie avec ce nom existe déjà.' }, 409); // 409 Conflict
    }
    if (existingError && existingError.code !== 'PGRST116') { // PGRST116 signifie "0 rows returned"
      console.error('Erreur Supabase (vérification existence catégorie):', existingError);
      return c.json({ error: existingError.message }, 500);
    }


    const { data, error } = await supabaseAdmin
      .from('categories')
      .insert([{ name: trimmedName }])
      .select(); // Retourne la catégorie nouvellement créée

    if (error) {
      console.error('Erreur Supabase (POST category):', error);
      return c.json({ error: error.message }, 500);
    }

    return c.json(data[0], 201); // Retourne le premier (et normalement unique) élément inséré
  } catch (err) {
    console.error('Erreur interne (POST category):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

// PUT /categories/:id → Update an existing category
categoriesRoute.put('/:id', async (c) => {
  try {
    const id = c.req.param('id');
    const body = await c.req.json();
    const { name } = body;

    if (!name || typeof name !== 'string' || name.trim() === '') {
      return c.json({ error: 'Le nom de la catégorie est requis et doit être une chaîne non vide.' }, 400);
    }

    const trimmedName = name.trim();

    // Vérifier si une autre catégorie avec ce nom (différente de celle en cours de modification) existe déjà
    const { data: existingData, error: existingError } = await supabaseAdmin
      .from('categories')
      .select('id')
      .eq('name', trimmedName)
      .neq('id', id) // Exclure la catégorie actuelle
      .single();

    if (existingData) {
      return c.json({ error: 'Une autre catégorie avec ce nom existe déjà.' }, 409); // 409 Conflict
    }
    if (existingError && existingError.code !== 'PGRST116') { // PGRST116 signifie "0 rows returned"
      console.error('Erreur Supabase (vérification existence catégorie):', existingError);
      return c.json({ error: existingError.message }, 500);
    }


    const { error } = await supabaseAdmin
      .from('categories')
      .update({ name: trimmedName })
      .eq('id', id);

    if (error) {
      console.error('Erreur Supabase (PUT category):', error);
      return c.json({ error: error.message }, 500);
    }

    return c.json({ success: true }, 200);
  } catch (err) {
    console.error('Erreur interne (PUT category):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

// DELETE /categories/:id → Delete a category
categoriesRoute.delete('/:id', async (c) => {
  try {
    const id = c.req.param('id');

    // Optionnel: Vérifier si des plats utilisent encore cette catégorie avant la suppression
    // Cela dépend de votre logique métier. Vous pourriez laisser Supabase gérer la contrainte
    // ou gérer la logique ici (ex: refuser la suppression si des plats existent, ou mettre à jour les plats).
    // Pour l'instant, on supprime directement.
    // Exemple de vérification (nécessite une relation category_id dans la table menu):
    // const { count, error: countError } = await supabaseAdmin
    //   .from('menu')
    //   .select('*', { count: 'exact', head: true })
    //   .eq('category_id', id); // Supposant une colonne category_id
    // if (countError) { /* ... gestion erreur ... */ }
    // if (count && count > 0) { return c.json({ error: 'Impossible de supprimer la catégorie car des plats y sont associés.' }, 400); }


    const { error } = await supabaseAdmin
      .from('categories')
      .delete()
      .eq('id', id);

    if (error) {
      console.error('Erreur Supabase (DELETE category):', error);
      return c.json({ error: error.message }, 500);
    }

    return c.json({ success: true }, 200);
  } catch (err) {
    console.error('Erreur interne (DELETE category):', err);
    return c.json({ error: 'Erreur interne du serveur' }, 500);
  }
});

export { categoriesRoute };