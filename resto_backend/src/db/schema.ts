import { pgTable, text, integer, uuid, timestamp } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';

// Définition du schéma Drizzle pour la table 'tables_data'
export const tablesData = pgTable('tables_data', {
    id: uuid('id').default(sql`gen_random_uuid()`).primaryKey(),

    // Le nom est obligatoire
    nom: text('nom').notNull(),

    // Le numéro de table est obligatoire
    numTable: integer('num_table').notNull(),

    // Les notes sont optionnelles
    notes: text('notes'),

    createdAt: timestamp('created_at', { withTimezone: true }).default(sql`now()`).notNull(),
});

// Type pour l'insertion (facilite la type-checking dans Hono)
export type NewTableData = typeof tablesData.$inferInsert;