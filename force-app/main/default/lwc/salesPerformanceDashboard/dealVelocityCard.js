import { LightningElement, api } from 'lwc';

export default class DealVelocityCard extends LightningElement {
    @api dealVelocity;
    
    get avgDealCycle() {
        return this.dealVelocity ? this.dealVelocity.avgDealCycle : 0;
    }
    
    get avgDealSize() {
        return this.dealVelocity ? this.dealVelocity.avgDealSize : 0;
    }
    
    get avgVelocity() {
        return this.dealVelocity ? this.dealVelocity.avgVelocity : 0;
    }
    
    get velocityTrend() {
        if (!this.dealVelocity || !this.dealVelocity.previousVelocity) return 0;
        
        const percentChange = ((this.dealVelocity.avgVelocity - this.dealVelocity.previousVelocity) / 
                                this.dealVelocity.previousVelocity) * 100;
        return Math.round(percentChange);
    }
    
    get trendIcon() {
        const trend = this.velocityTrend;
        if (trend > 0) return 'utility:up';
        if (trend < 0) return 'utility:down';
        return 'utility:right';
    }
    
    get trendClass() {
        const trend = this.velocityTrend;
        if (trend > 0) return 'slds-text-color_success';
        if (trend < 0) return 'slds-text-color_error';
        return 'slds-text-color_default';
    }
}
