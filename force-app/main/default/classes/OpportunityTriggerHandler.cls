public class OpportunityTriggerHandler {
    public static void calculateSalesMetrics(List<Opportunity> opportunities) {
        // Get all the user Ids from the opportunities
        Set<Id> userIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            userIds.add(opp.OwnerId);
        }
        
        // Query the territories for these users
        Map<Id, Territory__c> territoryByUserId = new Map<Id, Territory__c>();
        for (User u : [SELECT Id, Primary_Territory__c 
                        FROM User 
                        WHERE Id IN :userIds AND Primary_Territory__c != null]) {
            territoryByUserId.put(u.Id, new Territory__c(Id = u.Primary_Territory__c));
        }
        
        // Update territory field on opportunities
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp : opportunities) {
            if (territoryByUserId.containsKey(opp.OwnerId) && opp.Territory__c == null) {
                opp.Territory__c = territoryByUserId.get(opp.OwnerId).Id;
                oppsToUpdate.add(opp);
            }
        }
        
        // Update the opportunities
        if (!oppsToUpdate.isEmpty()) {
            try {
                update oppsToUpdate;
            } catch (Exception e) {
                System.debug('Error updating opportunities: ' + e.getMessage());
            }
        }
        
        // Now recalculate the YTD sales for each affected user
        calculateYTDSales(userIds);
    }
    
    private static void calculateYTDSales(Set<Id> userIds) {
        // Get the current year's start date
        Date currentYearStart = Date.newInstance(System.today().year(), 1, 1);
        
        // Query for won opportunities for these users in the current year
        Map<Id, Decimal> ytdSalesByUser = new Map<Id, Decimal>();
        for (AggregateResult ar : [SELECT OwnerId, SUM(Amount) totalAmount
                                   FROM Opportunity
                                   WHERE OwnerId IN :userIds
                                   AND StageName = 'Closed Won'
                                   AND CloseDate >= :currentYearStart
                                   GROUP BY OwnerId]) {
            Id userId = (Id)ar.get('OwnerId');
            Decimal totalAmount = (Decimal)ar.get('totalAmount');
            ytdSalesByUser.put(userId, totalAmount);
        }
        
        // Update the YTD Sales field on User objects
        List<User> usersToUpdate = new List<User>();
        for (Id userId : userIds) {
            Decimal ytdSales = ytdSalesByUser.containsKey(userId) ? ytdSalesByUser.get(userId) : 0;
            usersToUpdate.add(new User(
                Id = userId,
                YTD_Sales__c = ytdSales
            ));
        }
        
        // Update the users
        if (!usersToUpdate.isEmpty()) {
            try {
                update usersToUpdate;
            } catch (Exception e) {
                System.debug('Error updating users: ' + e.getMessage());
            }
        }
    }
}
