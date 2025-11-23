exports.up = function (knex) {
  return knex.schema.createTable('audit_logs', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').references('id').inTable('users').onDelete('SET NULL');
    table.string('action', 100).notNullable();
    table.string('entity_type', 50);
    table.uuid('entity_id');
    table.inet('ip_address');
    table.text('user_agent');
    table.jsonb('details');
    table.timestamp('created_at').defaultTo(knex.fn.now());

    table.index('user_id');
    table.index('created_at');
    table.index(['entity_type', 'entity_id']);
  });
};

exports.down = function (knex) {
  return knex.schema.dropTableIfExists('audit_logs');
};
