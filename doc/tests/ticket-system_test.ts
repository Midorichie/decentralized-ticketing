import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure that users can create tickets",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    
    // User creates a ticket
    let block = chain.mineBlock([
      Tx.contractCall('ticket-system', 'create-ticket', [
        types.utf8("My First Ticket"), 
        types.utf8("I'm having an issue with my account")
      ], user1.address)
    ]);
    
    // Assert ticket was created successfully
    block.receipts[0].result.expectOk().expectUint(1);
    
    // Read the ticket data
    const ticketData = chain.callReadOnlyFn(
      'ticket-system',
      'get-ticket',
      [types.uint(1)],
      user1.address
    );
    
    // Assert ticket data is correct
    const ticket = ticketData.result.expectSome().expectTuple();
    assertEquals(ticket['owner'], user1.address);
    assertEquals(ticket['title'], types.utf8("My First Ticket"));
    assertEquals(ticket['status'], types.uint(1)); // STATUS_OPEN
  },
});

Clarinet.test({
  name: "Ensure that only authorized users can update ticket status",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    const user2 = accounts.get('wallet_2')!;
    
    // User1 creates a ticket
    let block = chain.mineBlock([
      Tx.contractCall('ticket-system', 'create-ticket', [
        types.utf8("Test Ticket"), 
        types.utf8("Description")
      ], user1.address)
    ]);
    
    // Contract owner adds user2 as staff
    block = chain.mineBlock([
      Tx.contractCall('ticket-system', 'add-staff-member', [
        types.principal(user2.address)
      ], deployer.address)
    ]);
    
    // User2 (staff) updates the ticket status
    block = chain.mineBlock([
      Tx.contractCall('ticket-system', 'update-ticket-status', [
        types.uint(1), // ticket-id
        types.uint(2)  // STATUS_IN_PROGRESS
      ], user2.address)
    ]);
    
    // Assert update was successful
    block.receipts[0].result.expectOk().expectBool(true);
    
    // User1 (normal user) tries to update another user's ticket
    block = chain.mineBlock([
      Tx.contractCall('ticket-system', 'update-ticket-status', [
        types.uint(1), // ticket-id
        types.uint(3)  // STATUS_RESOLVED
      ], user1.address)
    ]);
    
    // This should fail with ERR_NOT_AUTHORIZED
    block.receipts[0].result.expectErr().expectUint(100);
  },
});
