exports.seed = async function (knex) {
  // Get users
  const users = await knex('users').select('id', 'email');
  const testUser = users.find((u) => u.email === 'user@finnaslaim.com');
  const johnDoe = users.find((u) => u.email === 'john.doe@example.com');

  if (!testUser || !johnDoe) {
    console.log('Users not found for seeding accounts');
    return;
  }

  // Inserts seed entries
  const accounts = await knex('accounts')
    .insert([
      {
        user_id: testUser.id,
        account_number: 'ACC1000001',
        account_type: 'checking',
        balance: 5000.00,
        currency: 'USD',
        status: 'active',
      },
      {
        user_id: testUser.id,
        account_number: 'ACC1000002',
        account_type: 'savings',
        balance: 15000.00,
        currency: 'USD',
        status: 'active',
      },
      {
        user_id: johnDoe.id,
        account_number: 'ACC1000003',
        account_type: 'checking',
        balance: 2500.00,
        currency: 'USD',
        status: 'active',
      },
    ])
    .returning('*');

  return accounts;
};
