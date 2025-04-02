public class SalesPerformanceDataImport {
    
    public static void importSampleData() {
        // Create Territories
        List<Territory__c> territories = createTerritories();
        insert territories;
        
        // Create Users with Primary Territories
        List<User> salesReps = createSalesReps(territories);
        // Users must be inserted one at a time due to mixed DML limitations
        for(User u : salesReps) {
            System.runAs(new User(Id = UserInfo.getUserId())) {
                insert u;
            }
        }
        
        // Query back the inserted users
        List<User> insertedReps = [SELECT Id, Name, Primary_Territory__c FROM User WHERE Username LIKE 'salesrep%@example.com%'];
        
        // Create Sales Targets
        List<Sales_Target__c> targets = createSalesTargets(territories, insertedReps);
        insert targets;
        
        // Create Opportunities
        List<Opportunity> opportunities = createOpportunities(territories, insertedReps);
        insert opportunities;
    }
    
    private static List<Territory__c> createTerritories() {
        List<Territory__c> territories = new List<Territory__c>();
        
        territories.add(new Territory__c(
            Name = 'Northeast',
            Territory_Code__c = 'NE001',
            Region__c = 'North',
            Annual_Target__c = 2000000
        ));
        
        territories.add(new Territory__c(
            Name = 'Southeast',
            Territory_Code__c = 'SE001',
            Region__c = 'South',
            Annual_Target__c = 1500000
        ));
        
        territories.add(new Territory__c(
            Name = 'Midwest',
            Territory_Code__c = 'MW001',
            Region__c = 'North',
            Annual_Target__c = 1750000
        ));
        
        territories.add(new Territory__c(
            Name = 'Southwest',
            Territory_Code__c = 'SW001',
            Region__c = 'South',
            Annual_Target__c = 1250000
        ));
        
        territories.add(new Territory__c(
            Name = 'West Coast',
            Territory_Code__c = 'WC001',
            Region__c = 'West',
            Annual_Target__c = 2500000
        ));
        
        return territories;
    }
    
    private static List<User> createSalesReps(List<Territory__c> territories) {
        // Get the standard user profile
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        List<User> salesReps = new List<User>();
        List<String> firstNames = new List<String>{'John', 'Sarah', 'Michael', 'Emma', 'David'};
        List<String> lastNames = new List<String>{'Smith', 'Johnson', 'Williams', 'Brown', 'Jones'};
        
        for (Integer i = 0; i < territories.size(); i++) {
            String uniqueSuffix = String.valueOf(System.currentTimeMillis() + i);
            User u = new User(
                FirstName = firstNames[i],
                LastName = lastNames[i],
                Email = 'salesrep' + i + '@example.com',
                Username = 'salesrep' + i + '@example.com.' + uniqueSuffix,
                Alias = 'srep' + i,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = p.Id,
                Primary_Territory__c = territories[i].Id
            );
            salesReps.add(u);
        }
        
        return salesReps;
    }
    
    private static List<Sales_Target__c> createSalesTargets(List<Territory__c> territories, List<User> salesReps) {
        List<Sales_Target__c> targets = new List<Sales_Target__c>();
        
        // Current year boundaries
        Date startOfYear = Date.newInstance(System.today().year(), 1, 1);
        Date endOfYear = Date.newInstance(System.today().year(), 12, 31);
        
        // Create annual targets for each sales rep
        for (Integer i = 0; i < salesReps.size(); i++) {
            targets.add(new Sales_Target__c(
                Target_Name__c = 'Annual Target - ' + salesReps[i].Name,
                Target_Amount__c = territories[i].Annual_Target__c,
                Start_Date__c = startOfYear,
                End_Date__c = endOfYear,
                Territory__c = territories[i].Id,
                Sales_Rep__c = salesReps[i].Id,
                Product_Family__c = 'Hardware',
                Status__c = 'Active'
            ));
        }
        
        // Create quarterly targets for each sales rep
        List<String> quarters = new List<String>{'Q1', 'Q2', 'Q3', 'Q4'};
        List<Date> quarterStarts = new List<Date>{
            Date.newInstance(System.today().year(), 1, 1),
            Date.newInstance(System.today().year(), 4, 1),
            Date.newInstance(System.today().year(), 7, 1),
            Date.newInstance(System.today().year(), 10, 1)
        };
        List<Date> quarterEnds = new List<Date>{
            Date.newInstance(System.today().year(), 3, 31),
            Date.newInstance(System.today().year(), 6, 30),
            Date.newInstance(System.today().year(), 9, 30),
            Date.newInstance(System.today().year(), 12, 31)
        };
        
        for (Integer i = 0; i < salesReps.size(); i++) {
            for (Integer q = 0; q < 4; q++) {
                targets.add(new Sales_Target__c(
                    Target_Name__c = quarters[q] + ' Target - ' + salesReps[i].Name,
                    Target_Amount__c = territories[i].Annual_Target__c / 4,
                    Start_Date__c = quarterStarts[q],
                    End_Date__c = quarterEnds[q],
                    Territory__c = territories[i].Id,
                    Sales_Rep__c = salesReps[i].Id,
                    Product_Family__c = 'Hardware',
                    Status__c = 'Active'
                ));
            }
        }
        
        // Create product family targets
        List<String> productFamilies = new List<String>{'Hardware', 'Software', 'Services'};
        for (Integer i = 0; i < salesReps.size(); i++) {
            for (String family : productFamilies) {
                targets.add(new Sales_Target__c(
                    Target_Name__c = family + ' Target - ' + salesReps[i].Name,
                    Target_Amount__c = territories[i].Annual_Target__c / 3,
                    Start_Date__c = startOfYear,
                    End_Date__c = endOfYear,
                    Territory__c = territories[i].Id,
                    Sales_Rep__c = salesReps[i].Id,
                    Product_Family__c = family,
                    Status__c = 'Active'
                ));
            }
        }
        
        return targets;
    }
    
    private static List<Opportunity> createOpportunities(List<Territory__c> territories, List<User> salesReps) {
        List<Opportunity> opportunities = new List<Opportunity>();
        
        // Create closed won opportunities
        Date[] pastCloseDates = new Date[]{
            Date.today().addMonths(-5),
            Date.today().addMonths(-4),
            Date.today().addMonths(-3),
            Date.today().addMonths(-2),
            Date.today().addMonths(-1)
        };
        
        // Different amount ranges for each territory to show variance
        Decimal[][] amountRanges = new Decimal[][]{
            new Decimal[]{50000, 100000},  // Northeast
            new Decimal[]{40000, 80000},   // Southeast
            new Decimal[]{45000, 90000},   // Midwest
            new Decimal[]{30000, 70000},   // Southwest
            new Decimal[]{60000, 120000}   // West Coast
        };
        
        // Create 25 closed won opportunities (5 per rep)
        for (Integer i = 0; i < salesReps.size(); i++) {
            for (Integer j = 0; j < 5; j++) {
                Decimal minAmount = amountRanges[i][0];
                Decimal maxAmount = amountRanges[i][1];
                Decimal randomAmount = minAmount + Math.random() * (maxAmount - minAmount);
                
                opportunities.add(new Opportunity(
                    Name = 'Opportunity ' + i + '-' + j,
                    StageName = 'Closed Won',
                    CloseDate = pastCloseDates[j],
                    Amount = randomAmount.setScale(2),
                    OwnerId = salesReps[i].Id,
                    Territory__c = territories[i].Id
                ));
            }
        }
        
        // Create open opportunities
        String[] stages = new String[]{
            'Prospecting',
            'Qualification',
            'Needs Analysis',
            'Value Proposition',
            'Id. Decision Makers',
            'Perception Analysis',
            'Proposal/Price Quote',
            'Negotiation/Review'
        };
        
        Date[] futureDates = new Date[]{
            Date.today().addDays(30),
            Date.today().addDays(60),
            Date.today().addDays(90),
            Date.today().addDays(120)
        };
        
        // Create 20 open opportunities (4 per rep)
        for (Integer i = 0; i < salesReps.size(); i++) {
            for (Integer j = 0; j < 4; j++) {
                Decimal minAmount = amountRanges[i][0];
                Decimal maxAmount = amountRanges[i][1];
                Decimal randomAmount = minAmount + Math.random() * (maxAmount - minAmount);
                
                // Random stage selection
                Integer stageIndex = Math.mod(Math.abs(Integer.valueOf(Math.random() * 1000)), stages.size());
                
                // Calculate probability based on stage
                Integer probability = (stageIndex + 1) * 10;
                if(probability > 90) probability = 90;
                
                opportunities.add(new Opportunity(
                    Name = 'Open Opp ' + i + '-' + j,
                    StageName = stages[stageIndex],
                    CloseDate = futureDates[j],
                    Amount = randomAmount.setScale(2),
                    OwnerId = salesReps[i].Id,
                    Territory__c = territories[i].Id,
                    Probability = probability
                ));
            }
        }
        
        // Create some closed lost opportunities
        Date[] recentDates = new Date[]{
            Date.today().addDays(-15),
            Date.today().addDays(-30),
            Date.today().addDays(-45),
            Date.today().addDays(-60)
        };
        
        // Create 15 closed lost opportunities (3 per rep)
        for (Integer i = 0; i < salesReps.size(); i++) {
            for (Integer j = 0; j < 3; j++) {
                Decimal minAmount = amountRanges[i][0];
                Decimal maxAmount = amountRanges[i][1];
                Decimal randomAmount = minAmount + Math.random() * (maxAmount - minAmount);
                
                opportunities.add(new Opportunity(
                    Name = 'Lost Opp ' + i + '-' + j,
                    StageName = 'Closed Lost',
                    CloseDate = recentDates[Math.mod(j, recentDates.size())],
                    Amount = randomAmount.setScale(2),
                    OwnerId = salesReps[i].Id,
                    Territory__c = territories[i].Id
                ));
            }
        }
        
        return opportunities;
    }
}