import { LightningElement, api, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';

export default class TerritoryPerformanceChart extends LightningElement {
    @api territorySummary;
    chartInitialized = false;
    chart;
    
    renderedCallback() {
        if (this.territorySummary && !this.chartInitialized) {
            this.chartInitialized = true;
            Promise.all([
                loadScript(this, 'https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.9.4/Chart.min.js'),
            ])
                .then(() => {
                    this.initializeChart();
                })
                .catch(error => {
                    console.error('Error loading ChartJS', error);
                });
        }
    }
    
    initializeChart() {
        const ctx = this.template.querySelector('canvas.territory-chart').getContext('2d');
        
        // Prepare data
        const territoryNames = this.territorySummary.territories.map(territory => territory.name);
        const actualSales = this.territorySummary.territories.map(territory => territory.actualSales);
        const targetSales = this.territorySummary.territories.map(territory => territory.targetSales);
        
        this.chart = new window.Chart(ctx, {
            type: 'horizontalBar',
            data: {
                labels: territoryNames,
                datasets: [
                    {
                        label: 'Actual Sales',
                        backgroundColor: '#1589EE',
                        data: actualSales,
                    },
                    {
                        label: 'Target',
                        backgroundColor: '#AAAAAA',
                        data: targetSales,
                    },
                ],
            },
            options: {
                title: {
                    display: true,
                    text: 'Territory Performance',
                },
                responsive: true,
                scales: {
                    xAxes: [
                        {
                            ticks: {
                                beginAtZero: true,
                                callback: function(value) {
                                    return '$' + value;
                                },
                            },
                        },
                    ],
                },
            },
        });
    }
}