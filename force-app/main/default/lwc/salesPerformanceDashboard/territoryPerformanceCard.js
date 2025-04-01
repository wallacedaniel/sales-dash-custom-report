import { LightningElement, api } from 'lwc';

export default class TerritoryPerformanceCard extends LightningElement {
    @api territorySummary;
    
    get topTerritory() {
        if (this.territorySummary && this.territorySummary.territories && this.territorySummary.territories.length > 0) {
            let territories = [...this.territorySummary.territories];
            territories.sort((a, b) => b.performanceScore - a.performanceScore);
            return territories[0];
        }
        return null;
    }
    
    get averageAttainment() {
        if (this.territorySummary && this.territorySummary.territories && this.territorySummary.territories.length > 0) {
            const total = this.territorySummary.territories.reduce((sum, territory) => sum + territory.attainmentPercentage, 0);
            return Math.round(total / this.territorySummary.territories.length);
        }
        return 0;
    }
    
    get lowestTerritory() {
        if (this.territorySummary && this.territorySummary.territories && this.territorySummary.territories.length > 0) {
            let territories = [...this.territorySummary.territories];
            territories.sort((a, b) => a.attainmentPercentage - b.attainmentPercentage);
            return territories[0];
        }
        return null;
    }
}