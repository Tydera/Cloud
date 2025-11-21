exports.seed = async function (knex) {
  // Get accounts
  const accounts = await knex('accounts').select('id', 'account_number');
  const account1 = accounts.find((a) => a.account_number === 'ACC1000001');
  const account2 = accounts.find((a) => a.account_number === 'ACC1000002');

  if (!account1 || !account2) {
    console.log('Accounts not found for seeding transactions');
    return;
  }

  // Inserts seed entries
  await knex('transactions').insert([
    {
      account_id: account1.id,
      transaction_type: 'deposit',
      amount: 5000.00,
      currency: 'USD',
      description: 'Initial deposit',
      reference_number: 'TXN1000001',
      status: 'completed',
      processed_at: knex.fn.now(),
    },
    {
      account_id: account1.id,
      transaction_type: 'withdrawal',
      amount: 100.00,
      currency: 'USD',
      description: 'ATM withdrawal',
      reference_number: 'TXN1000002',
      status: 'completed',
      processed_at: knex.fn.now(),
    },
    {
      account_id: account2.id,
      transaction_type: 'deposit',
      amount: 15000.00,
      currency: 'USD',
      description: 'Initial savings deposit',
      reference_number: 'TXN1000003',
      status: 'completed',
      processed_at: knex.fn.now(),
    },
  ]);
};
