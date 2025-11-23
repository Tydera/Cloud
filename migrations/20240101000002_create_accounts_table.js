exports.up = function (knex) {
  return knex.schema.createTable('accounts', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.string('account_number', 50).notNullable().unique();
    table.string('account_type', 50).notNullable();
    table.decimal('balance', 15, 2).defaultTo(0.00);
    table.string('currency', 3).defaultTo('USD');
    table.string('status', 20).defaultTo('active');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());

    table.index('user_id');
    table.index('account_number');
    table.index(['user_id', 'status']);
  });
};

exports.down = function (knex) {
  return knex.schema.dropTableIfExists('accounts');
};
