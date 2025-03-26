@isTest
public class OpportunityTriggerHandlerTest {
    @testSetup
    static void setupTestData() {
        // Create a test territory
        Territory__c territory = new Territory__c(
            Name = 'Test Territory',
            Territory_Code__c = 'TEST',
            Region__c = 'North',
            Annual_Target__c = 500000
        );
        insert territory;
        
        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            Primary_Territory__c = territory.Id
        );
        insert u;
    }
    
    @isTest
    static void testCalculateSalesMetrics() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'User' LIMIT 1];
        Territory__c territory = [SELECT Id FROM Territory__c WHERE Name = 'Test Territory' LIMIT 1];
        
        Test.startTest();
        // Create a new opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 100000,
            OwnerId = testUser.Id
        );
        insert opp;
        
        // The trigger should set the Territory field
        opp = [SELECT Id, Territory__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(territory.Id, opp.Territory__c, 'Territory should be populated based on owner');
        
        // Now close the opportunity
        opp.StageName = 'Closed Won';
        update opp;
        
        Test.stopTest();
        
        // Verify YTD Sales was updated
        testUser = [SELECT Id, YTD_Sales__c FROM User WHERE Id = :testUser.Id];
        System.assertEquals(100000, testUser.YTD_Sales__c, 'YTD Sales should be updated');
    }
}