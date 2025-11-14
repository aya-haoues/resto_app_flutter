// routes/commandes.ts
import { Hono } from 'hono';
import { supabaseAdmin } from '../index';

const commandesRoute = new Hono();

commandesRoute.post('/', async (c) => {
    try {
        console.log('📥 Requête POST reçue sur /commandes');

        let body;
        try {
            // Vérifiez le Content-Type
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

        // On récupère les champs nécessaires pour l'insertion
        const { client_name, total_price, items, table_number, notes } = body;

        // Validation de base des données
        if (!total_price || typeof total_price !== 'number' || !items || items.length === 0) {
            console.log('❌ Validation échouée:', { total_price, items });
            c.status(400); // Bad Request
            return c.json({ message: 'Données de commande incomplètes ou mal formées.' });
        }

        // --- 1. Insertion dans la table 'orders' ---
        // Cette table stocke les informations principales de la commande (client, table, etc.)
        const { data: orderData, error: orderError } = await supabaseAdmin
            .from('orders')
            .insert({
                client_name: client_name || 'Client sur place',
                table_number: table_number,
                notes: notes,
            })
            .select('id') // Récupère l'ID pour l'étape suivante
            .single();

        if (orderError) {
            console.error('❌ Erreur Supabase (Table orders) :', orderError.message);
            c.status(500);
            return c.json({ message: `Erreur lors de l'insertion dans la table 'orders': ${orderError.message}` });
        }

        const orderId = orderData.id;
        console.log('✅ Commande insérée dans la table "orders" avec ID :', orderId);

        // --- 2. Insertion dans la table 'commandes' ---
        // Cette table stocke le total et référence la commande dans 'orders'
        const { data: commandeData, error: commandeError } = await supabaseAdmin
            .from('commandes')
            .insert({
                order_id: orderId, // Lien vers la table 'orders'
                client_name: client_name || 'Client sur place',
                total_price: total_price,
                table_number: table_number,
                notes: notes,
            })
            .select('id') // Récupère l'ID pour l'étape suivante
            .single();

        if (commandeError) {
            console.error('❌ Erreur Supabase (Table commandes) :', commandeError.message);
            c.status(500);
            return c.json({ message: `Erreur lors de l'insertion dans la table 'commandes': ${commandeError.message}` });
        }

        const commandeId = commandeData.id;
        console.log('✅ Commande insérée dans la table "commandes" avec ID :', commandeId);

        // --- 3. Préparation et Insertion des articles pour la table 'commande_items' ---
        const commandeItemsToInsert = items.map((item: any) => ({
            commande_id: commandeId, // Clé étrangère vers la table 'commandes'
            // Le nom des colonnes ici DOIT correspondre à 'public.commande_items'
            food_name: item.name,
            price: item.price,
            quantity: item.quantity || 1,
        }));

        const { error: itemsError } = await supabaseAdmin
            .from('commande_items') // Nom exact de la table
            .insert(commandeItemsToInsert);

        if (itemsError) {
            console.error('❌ Erreur Supabase (Table commande_items) :', itemsError.message);
            // La commande principale est créée, mais les items ont échoué
            c.status(500);
            return c.json({ message: `Erreur lors de l'enregistrement des articles : ${itemsError.message}. Vérifiez les noms de colonnes.` });
        }

        // --- 4. MISE À JOUR DU STATUT DE LA TABLE (si applicable) ---
        if (table_number !== undefined && table_number !== null) {
            console.log(`🔄 Tentative de mise à jour du statut de la table ${table_number}...`);
            const { error: tableUpdateError } = await supabaseAdmin
                .from('tables') // Remplacez par le nom de votre table de tables
                .update({
                    status: 'occupied', // ou 'Occupée' selon votre schéma, converti en minuscule plus bas
                    order_summary: `${items.length} plat(s) pour ${client_name || 'Client sur place'}`, // Exemple de résumé
                    time_occupied: new Date().toISOString(), // Enregistrer l'heure d'occupation
                })
                .eq('id', table_number); // Supposons que 'table_number' corresponde à 'id' dans la table 'tables'

            if (tableUpdateError) {
                console.error('❌ Erreur lors de la mise à jour du statut de la table:', tableUpdateError.message);
                // ATTENTION: La commande a été créée, mais la table n'a pas été mise à jour.
                // Vous pourriez vouloir annuler la commande ou gérer cette erreur différemment.
                // Pour l'instant, on loggue l'erreur mais on continue.
            } else {
                 console.log(`✅ Statut de la table ${table_number} mis à jour.`);
            }
        } else {
            console.log('ℹ️ Aucun numéro de table fourni, mise à jour du statut ignorée.');
        }

        // --- 5. Succès ---
        console.log('✅ Commande complète enregistrée !');
        return c.json({
            message: 'Commande enregistrée avec succès',
            order_id: orderId,
            commande_id: commandeId,
        }, 200);

    } catch (error: any) {
        // Erreur de JSON mal formé ou autre erreur inattendue
        console.error('❌ Erreur Hono/Serveur interne :', error.message);
        c.status(500);
        return c.json({ message: 'Erreur interne du serveur lors du traitement de la requête.' });
    }
});

export { commandesRoute };