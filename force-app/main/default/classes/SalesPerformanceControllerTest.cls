@isTest
public class SalesPerformanceControllerTest {
    // Setup test data
    @testSetup
    static void setupTestData() {
        // Create test territories
        List<Territory__c> territories = new List<Territory__c>();
        territories.add(new Territory__c(
            Name = 'North',
            Territory_Code__c = 'N001',
            Region__c = 'North',
            Annual_Target__c = 1000000
        ));
        territories.add(new Territory__c(
            Name = 'South',
            Territory_Code__c = 'S001',
            Region__c = 'South',
            Annual_Target__c = 750000
        ));
        territories.add(new Territory__c(
            Name = 'East',
            Territory_Code__c = 'E001',
            Region__c = 'East',
            Annual_Target__c = 500000
        ));
        territories.add(new Territory__c(
            Name = 'West',
            Territory_Code__c = 'W001',
            Region__c = 'West',
            Annual_Target__c = 1250000
        ));
        insert territories;
        
        // Create test users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        List<User> users = new List<User>();
        for (Integer i = 0; i < 4; i++) {
            User u = new User(
                FirstName = 'Test',
                LastName = 'User' + i,
                Email = 'testuser' + i + '@example.com',
                Username = 'testuser' + i + '@example.com' + System.currentTimeMillis(),
                Alias = 'tuser' + i,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = p.Id,
                Primary_Territory__c = territories[i].Id
            );
            users.add(u);
        }
        insert users;
        
        // Create sales targets
        List<Sales_Target__c> targets = new List<Sales_Target__c>();
        for (Integer i = 0; i < 4; i++) {
            Date startDate = Date.newInstance(System.today().year(), 1, 1);
            Date endDate = Date.newInstance(System.today().year(), 12, 31);
            
            Sales_Target__c target = new Sales_Target__c(
                Target_Name__c = 'Target ' + i,
                Target_Amount__c = 250000,
                Start_Date__c = startDate,
                End_Date__c = endDate,
                Territory__c = territories[i].Id,
                Sales_Rep__c = users[i].Id,
                Product_Family__c = 'Hardware',
                Status__c = 'Active'
            );
            targets.add(target);
        }
        insert targets;
        
        // Create opportunities
        List<Opportunity> opportunities = new List<Opportunity>();
        
        // Past closed opportunities
        Date closeDatePast = Date.today().addMonths(-2);
        for (Integer i = 0; i < 4; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Past Opp ' + i,
                StageName = 'Closed Won',
                CloseDate = closeDatePast,
                Amount = 50000,
                OwnerId = users[i].Id,
                Territory__c = territories[i].Id
            );
            opportunities.add(opp);
        }
        
        // Current open opportunities
        Date closeDateFuture = Date.today().addMonths(2);
        for (Integer i = 0; i < 4; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Current Opp ' + i,
                StageName = 'Negotiation',
                CloseDate = closeDateFuture,
                Amount = 75000,
                OwnerId = users[i].Id,
                Territory__c = territories[i].Id,
                Probability = 70
            );
            opportunities.add(opp);
        }
        
        // Some lost opportunities
        Date closeDateRecent = Date.today().addDays(-10);
        for (Integer i = 0; i < 2; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Lost Opp ' + i,
                StageName = 'Closed Lost',
                CloseDate = closeDateRecent,
                Amount = 60000,
                OwnerId = users[i].Id,
                Territory__c = territories[i].Id
            );
            opportunities.add(opp);
        }
        
        insert opportunities;
    }
    
    @isTest
    static void testGetSalesSummary() {
        Test.startTest();
        Map<String, Object> result = SalesPerformanceController.getSalesSummary();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.get('totalSales'), 'Total sales should not be null');
        System.assertNotEquals(null, result.get('targetAmount'), 'Target amount should not be null');
        
        Decimal totalSales = (Decimal)result.get('totalSales');
        Decimal targetAmount = (Decimal)result.get('targetAmount');
        
        // We created 4 closed won opportunities at $50k each
        System.assertEquals(200000, totalSales, 'Total sales should match our test data');
        // We created 4 sales targets at $250k each
        System.assertEquals(1000000, targetAmount, 'Target amount should match our test data');
    }
    
    @isTest
    static void testGetTerritorySummary() {
        Test.startTest();
        Map<String, Object> result = SalesPerformanceController.getTerritorySummary();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.get('territories'), 'Territories should not be null');
        
        List<Map<String, Object>> territories = (List<Map<String, Object>>)result.get('territories');
        System.assertEquals(4, territories.size(), 'Should have 4 territories');
        
        // Verify territory data
        for (Map<String, Object> territory : territories) {
            String name = (String)territory.get('name');
            Decimal targetSales = (Decimal)territory.get('targetSales');
            Decimal actualSales = (Decimal)territory.get('actualSales');
            
            System.assertNotEquals(null, name, 'Territory name should not be null');
            System.assertNotEquals(null, targetSales, 'Target sales should not be null');
            System.assertNotEquals(null, actualSales, 'Actual sales should not be null');
            
            // Each territory has 1 closed won opportunity for $50k
            System.assertEquals(50000, actualSales, 'Actual sales should match our test data for ' + name);
        }
    }
    
    @isTest
    static void testGetDealVelocity() {
        Test.startTest();
        Map<String, Object> result = SalesPerformanceController.getDealVelocity();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.get('avgDealCycle'), 'Average deal cycle should not be null');
        System.assertNotEquals(null, result.get('avgDealSize'), 'Average deal size should not be null');
    }
    
    @isTest
    static void testGetSalesPipeline() {
        Test.startTest();
        List<Map<String, Object>> result = SalesPerformanceController.getSalesPipeline();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Should have pipeline data');
        
        // Verify we have the expected stages
        Set<String> stageNames = new Set<String>();
        for (Map<String, Object> stage : result) {
            String stageName = (String)stage.get('stageName');
            stageNames.add(stageName);
        }
        
        System.assert(stageNames.contains('Negotiation') || stageNames.contains('Closed Won') || stageNames.contains('Closed Lost'), 
                     'Pipeline should contain expected stages');
    }
}