public class SalesTargetTriggerHandler {
    public static void updateTargetAttainment(List<Sales_Target__c> targets) {
        // Get all the user Ids from the targets
        Set<Id> userIds = new Set<Id>();
        for (Sales_Target__c target : targets) {
            if (target.Sales_Rep__c != null) {
                userIds.add(target.Sales_Rep__c);
            }
        }
        
        // OpportunityTriggerHandler already has the logic to calculate YTD sales
        // So we can reuse that method
        OpportunityTriggerHandler.calculateYTDSales(userIds);
    }
}