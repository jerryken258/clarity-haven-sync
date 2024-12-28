import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new team",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('haven_sync', 'create-team', [
                types.ascii("Remote Dev Team")
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk();
        
        // Verify team creation
        let getTeamBlock = chain.mineBlock([
            Tx.contractCall('haven_sync', 'get-team-info', [
                types.uint(0)
            ], deployer.address)
        ]);
        
        const teamInfo = getTeamBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(teamInfo['name'], "Remote Dev Team");
    }
});

Clarinet.test({
    name: "Can set and get user availability",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('haven_sync', 'set-availability', [
                types.list([
                    types.tuple({
                        'start-time': types.uint(1630000000),
                        'end-time': types.uint(1630003600),
                        'timezone': types.ascii("UTC")
                    })
                ])
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk();
        
        // Verify availability
        let getAvailBlock = chain.mineBlock([
            Tx.contractCall('haven_sync', 'get-user-availability', [
                types.principal(deployer.address)
            ], deployer.address)
        ]);
        
        getAvailBlock.receipts[0].result.expectOk().expectSome();
    }
});

Clarinet.test({
    name: "Can schedule and confirm meetings",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        // First create a team
        let createTeamBlock = chain.mineBlock([
            Tx.contractCall('haven_sync', 'create-team', [
                types.ascii("Test Team")
            ], deployer.address)
        ]);
        
        createTeamBlock.receipts[0].result.expectOk();
        
        // Add member
        let addMemberBlock = chain.mineBlock([
            Tx.contractCall('haven_sync', 'add-team-member', [
                types.uint(0),
                types.principal(wallet1.address)
            ], deployer.address)
        ]);
        
        addMemberBlock.receipts[0].result.expectOk();
        
        // Schedule meeting
        let scheduleMeetingBlock = chain.mineBlock([
            Tx.contractCall('haven_sync', 'schedule-meeting', [
                types.uint(0),
                types.uint(1630000000),
                types.uint(1630003600),
                types.list([types.principal(wallet1.address)])
            ], deployer.address)
        ]);
        
        scheduleMeetingBlock.receipts[0].result.expectOk();
        
        // Confirm meeting
        let confirmMeetingBlock = chain.mineBlock([
            Tx.contractCall('haven_sync', 'confirm-meeting', [
                types.uint(0)
            ], wallet1.address)
        ]);
        
        confirmMeetingBlock.receipts[0].result.expectOk();
    }
});