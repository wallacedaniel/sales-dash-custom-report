import { LightningElement, api, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';

export default class TargetAttainmentChart extends LightningElement {
    @api salesSummary;
    chartInitialized = false;
    chart;
    
    renderedCallback() {
        if (this.salesSummary && !this.chartInitialized) {
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
        const ctx = this.template.querySelector('canvas.attainment-chart').getContext('2d');
        
        // Calculate data for gauge chart
        const attainmentPercentage = Math.round((this.salesSummary.totalSales / this.salesSummary.targetAmount) * 100);
        const remainder = 100 - attainmentPercentage;
        
        let color = '#F44336'; // Red
        if (attainmentPercentage >= 100) {
            color = '#4CAF50'; // Green
        } else if (attainmentPercentage >= 75) {
            color = '#FFC107'; // Yellow
        }
        
        this.chart = new window.Chart(ctx, {
            type: 'doughnut',
            data: {
                datasets: [
                    {
                        data: [attainmentPercentage, remainder],
                        backgroundColor: [color, '#EEEEEE'],
                    },
                ],
                labels: ['Attainment', 'Remaining'],
            },
            options: {
                cutoutPercentage: 70,
                responsive: true,
                tooltips: {
                    callbacks: {
                        label: function(tooltipItem, data) {
                            return data.labels[tooltipItem.index] + ': ' + data.datasets[0].data[tooltipItem.index] + '%';
                        },
                    },
                },
            },
        });
        
        // Add text in the middle of the doughnut
        Chart.pluginService.register({
            beforeDraw: function(chart) {
                const width = chart.chart.width;
                const height = chart.chart.height;
                const ctx = chart.chart.ctx;
                
                ctx.restore();
                const fontSize = (height / 114).toFixed(2);
                ctx.font = fontSize + 'em sans-serif';
                ctx.textBaseline = 'middle';
                
                const text = attainmentPercentage + '%';
                const textX = Math.round((width - ctx.measureText(text).width) / 2);
                const textY = height / 2;
                
                ctx.fillText(text, textX, textY);
                ctx.save();
            },
        });
    }
}
