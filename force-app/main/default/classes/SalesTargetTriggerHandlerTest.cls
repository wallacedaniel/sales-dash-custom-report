@isTest
public class SalesTargetTriggerHandlerTest {
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
        
        // Create a closed won opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            Amount = 75000,
            OwnerId = u.Id,
            Territory__c = territory.Id
        );
        insert opp;
    }
    
    @isTest
    static void testUpdateTargetAttainment() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'User' LIMIT 1];
        Territory__c territory = [SELECT Id FROM Territory__c WHERE Name = 'Test Territory' LIMIT 1];
        
        Test.startTest();
        // Create a new sales target
        Sales_Target__c target = new Sales_Target__c(
            Target_Name__c = 'Test Target',
            Target_Amount__c = 100000,
            Start_Date__c = Date.newInstance(System.today().year(), 1, 1),
            End_Date__c = Date.newInstance(System.today().year(), 12, 31),
            Territory__c = territory.Id,
            Sales_Rep__c = testUser.Id,
            Product_Family__c = 'Hardware',
            Status__c = 'Active'
        );
        insert target;
        Test.stopTest();
        
        // Verify YTD Sales was calculated
        testUser = [SELECT Id, YTD_Sales__c FROM User WHERE Id = :testUser.Id];
        System.assertEquals(75000, testUser.YTD_Sales__c, 'YTD Sales should be calculated correctly');
    }
}