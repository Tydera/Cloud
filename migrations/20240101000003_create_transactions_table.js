exports.up = function (knex) {
  return knex.schema.createTable('transactions', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('account_id').notNullable().references('id').inTable('accounts').onDelete('CASCADE');
    table.string('transaction_type', 50).notNullable();
    table.decimal('amount', 15, 2).notNullable();
    table.string('currency', 3).defaultTo('USD');
    table.text('description');
    table.string('reference_number', 100).unique();
    table.string('status', 20).defaultTo('pending');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('processed_at');

    table.index('account_id');
    table.index('reference_number');
    table.index(['account_id', 'created_at']);
    table.index(['account_id', 'status']);
  });
};

exports.down = function (knex) {
  return knex.schema.dropTableIfExists('transactions');
};
