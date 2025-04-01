import { LightningElement, api } from 'lwc';

export default class SalesSummaryCard extends LightningElement {
    @api salesSummary;
    
    get totalSales() {
        return this.salesSummary ? this.salesSummary.totalSales : 0;
    }

    get targetAmount() {
        return this.salesSummary ? this.salesSummary.targetAmount : 0;
    }

    get attainmentPercentage() {
        if (this.salesSummary && this.salesSummary.targetAmount > 0) {
            return Math.round((this.salesSummary.totalSales / this.salesSummary.targetAmount) * 100);
        }
        return 0;
    }

    get attainmentClass() {
        const percentage = this.attainmentPercentage;
        if (percentage >= 100) return 'slds-text-color_success';
        if (percentage >= 75) return 'slds-text-color_default';
        return 'slds-text-color_error';
    }
}