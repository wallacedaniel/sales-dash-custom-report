public with sharing class SalesPerformanceController {
    /**
     * Get summary information about sales performance
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getSalesSummary() {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // Get current year
            Date currentYearStart = Date.newInstance(System.today().year(), 1, 1);
            
            // Calculate total sales YTD
            AggregateResult salesResult = [SELECT SUM(Amount) totalAmount
                                          FROM Opportunity
                                          WHERE StageName = 'Closed Won'
                                          AND CloseDate >= :currentYearStart];
            
            Decimal totalSales = (Decimal)salesResult.get('totalAmount');
            if (totalSales == null) totalSales = 0;
            
            // Get total target amount for the year
            AggregateResult targetResult = [SELECT SUM(Target_Amount__c) totalTarget
                                           FROM Sales_Target__c
                                           WHERE Start_Date__c >= :currentYearStart
                                           AND Status__c = 'Active'];
            
            Decimal targetAmount = (Decimal)targetResult.get('totalTarget');
            if (targetAmount == null) targetAmount = 0;
            
            // Top performing sales reps
            List<Map<String, Object>> topReps = new List<Map<String, Object>>();
            for(AggregateResult ar : [SELECT OwnerId, Owner.Name, SUM(Amount) totalSales
                                     FROM Opportunity
                                     WHERE StageName = 'Closed Won'
                                     AND CloseDate >= :currentYearStart
                                     GROUP BY OwnerId, Owner.Name
                                     ORDER BY SUM(Amount) DESC
                                     LIMIT 5]) {
                                         
                Map<String, Object> rep = new Map<String, Object>();
                rep.put('id', (Id)ar.get('OwnerId'));
                rep.put('name', (String)ar.get('Name'));
                rep.put('totalSales', (Decimal)ar.get('totalSales'));
                
                topReps.add(rep);
            }
            
            // Populate result
            result.put('totalSales', totalSales);
            result.put('targetAmount', targetAmount);
            result.put('topPerformers', topReps);
            
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting sales summary: ' + e.getMessage());
        }
    }
    
    /**
     * Get territory performance summary
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getTerritorySummary() {
        Map<String, Object> result = new Map<String, Object>();
        List<Map<String, Object>> territories = new List<Map<String, Object>>();
        
        try {
            // Get current year
            Date currentYearStart = Date.newInstance(System.today().year(), 1, 1);
            
            // Get territories with sales data
            Map<Id, Decimal> salesByTerritory = new Map<Id, Decimal>();
            for(AggregateResult ar : [SELECT Territory__c, SUM(Amount) totalSales
                                     FROM Opportunity
                                     WHERE StageName = 'Closed Won'
                                     AND CloseDate >= :currentYearStart
                                     AND Territory__c != null
                                     GROUP BY Territory__c]) {
                                         
                Id territoryId = (Id)ar.get('Territory__c');
                Decimal totalSales = (Decimal)ar.get('totalSales');
                salesByTerritory.put(territoryId, totalSales);
            }
            
            // Get territories with targets
            for(Territory__c territory : [SELECT Id, Name, Territory_Code__c, Region__c, Annual_Target__c
                                         FROM Territory__c
                                         WHERE Annual_Target__c > 0]) {
                                             
                Map<String, Object> territoryData = new Map<String, Object>();
                territoryData.put('id', territory.Id);
                territoryData.put('name', territory.Name);
                territoryData.put('code', territory.Territory_Code__c);
                territoryData.put('region', territory.Region__c);
                territoryData.put('targetSales', territory.Annual_Target__c);
                
                Decimal actualSales = salesByTerritory.containsKey(territory.Id) ? 
                                    salesByTerritory.get(territory.Id) : 0;
                territoryData.put('actualSales', actualSales);
                
                Decimal attainmentPercentage = territory.Annual_Target__c > 0 ? 
                                             (actualSales / territory.Annual_Target__c) * 100 : 0;
                territoryData.put('attainmentPercentage', Math.round(attainmentPercentage));
                
                // Calculate a performance score
                // Higher scores for territories that are ahead of target
                Decimal performanceScore = attainmentPercentage + (actualSales / 10000);
                territoryData.put('performanceScore', performanceScore);
                
                territories.add(territoryData);
            }
            
            result.put('territories', territories);
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting territory summary: ' + e.getMessage());
        }
    }
    
    /**
     * Get deal velocity metrics
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDealVelocity() {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // Current period
            Date sixMonthsAgo = System.today().addMonths(-6);
            Date currentDate = System.today();
            
            // Previous period
            Date twelveMonthsAgo = System.today().addMonths(-12);
            Date sixMonthsPlus1DayAgo = sixMonthsAgo.addDays(-1);
            
            // Current period metrics
            AggregateResult currentMetrics = [SELECT 
                                             AVG(CloseDate - CreatedDate) avgDealCycle,
                                             AVG(Amount) avgDealSize,
                                             AVG(Deal_Velocity__c) avgVelocity
                                             FROM Opportunity
                                             WHERE StageName = 'Closed Won'
                                             AND CloseDate >= :sixMonthsAgo
                                             AND CloseDate <= :currentDate];
            
            Decimal avgDealCycle = (Decimal)currentMetrics.get('avgDealCycle');
            if (avgDealCycle == null) avgDealCycle = 0;
            
            Decimal avgDealSize = (Decimal)currentMetrics.get('avgDealSize');
            if (avgDealSize == null) avgDealSize = 0;
            
            Decimal avgVelocity = (Decimal)currentMetrics.get('avgVelocity');
            if (avgVelocity == null) avgVelocity = 0;
            
            // Previous period velocity for trend calculation
            AggregateResult previousMetrics = [SELECT AVG(Deal_Velocity__c) avgVelocity
                                              FROM Opportunity
                                              WHERE StageName = 'Closed Won'
                                              AND CloseDate >= :twelveMonthsAgo
                                              AND CloseDate <= :sixMonthsPlus1DayAgo];
            
            Decimal previousVelocity = (Decimal)previousMetrics.get('avgVelocity');
            if (previousVelocity == null) previousVelocity = 0;
            
            // Populate result
            result.put('avgDealCycle', Math.round(avgDealCycle));
            result.put('avgDealSize', avgDealSize);
            result.put('avgVelocity', avgVelocity);
            result.put('previousVelocity', previousVelocity);
            
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting deal velocity: ' + e.getMessage());
        }
    }
    
    /**
     * Get sales pipeline data for chart
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getSalesPipeline() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        
        try {
            for(AggregateResult ar : [SELECT StageName, SUM(Amount) amount, COUNT(Id) opportunityCount
                                     FROM Opportunity
                                     WHERE IsClosed = false
                                     OR CloseDate = THIS_FISCAL_YEAR
                                     GROUP BY StageName
                                     ORDER BY StageName]) {
                                         
                Map<String, Object> stageData = new Map<String, Object>();
                stageData.put('stageName', (String)ar.get('StageName'));
                stageData.put('amount', (Decimal)ar.get('amount'));
                stageData.put('opportunityCount', (Integer)ar.get('opportunityCount'));
                
                result.add(stageData);
            }
            
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting sales pipeline: ' + e.getMessage());
        }
    }
}