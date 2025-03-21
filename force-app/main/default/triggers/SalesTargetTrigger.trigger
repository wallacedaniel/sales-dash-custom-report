trigger SalesTargetTrigger on Sales_Target__c (after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            SalesTargetTriggerHandler.updateTargetAttainment(Trigger.new);
        }
    }
}