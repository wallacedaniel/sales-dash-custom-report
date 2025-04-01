import { LightningElement, wire } from 'lwc';
import getSalesPipeline from '@salesforce/apex/SalesPerformanceController.getSalesPipeline';

export default class SalesPipelineChart extends LightningElement {
    chartConfiguration;
    isLoading = true;
    
    @wire(getSalesPipeline)
    wiredSalesPipeline({ error, data }) {
        if (data) {
            this.prepareChartData(data);
            this.isLoading = false;
        } else if (error) {
            this.error = error;
            this.isLoading = false;
            console.error('Error loading sales pipeline data', error);
        }
    }
    
    prepareChartData(pipelineData) {
        // Transform data for the chart
        let stages = [];
        let amounts = [];
        let colors = [];
        
        pipelineData.forEach(item => {
            stages.push(item.stageName);
            amounts.push(item.amount);
            
            // Different colors for different stages
            if (item.stageName.includes('Closed Won')) {
                colors.push('#4CAF50'); // Green
            } else if (item.stageName.includes('Closed Lost')) {
                colors.push('#F44336'); // Red
            } else {
                colors.push('#1589EE'); // Blue
            }
        });
        
        this.chartConfiguration = {
            type: 'bar',
            data: {
                labels: stages,
                datasets: [
                    {
                        label: 'Amount',
                        backgroundColor: colors,
                        data: amounts,
                    },
                ],
            },
            options: {
                title: {
                    display: true,
                    text: 'Sales Pipeline by Stage',
                },
                responsive: true,
                legend: {
                    display: false,
                },
                scales: {
                    xAxes: [
                        {
                            ticks: {
                                autoSkip: false,
                                maxRotation: 45,
                                minRotation: 45,
                            },
                        },
                    ],
                    yAxes: [
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
        };
    }
    
    renderedCallback() {
        if (this.chartConfiguration && !this.chartInitialized) {
            this.chartInitialized = true;
            Promise.all([
                loadScript(this, 'https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.9.4/Chart.min.js'),
            ])
                .then(() => {
                    const canvas = document.createElement('canvas');
                    this.template.querySelector('div.chart-container').appendChild(canvas);
                    const ctx = canvas.getContext('2d');
                    this.chart = new window.Chart(ctx, this.chartConfiguration);
                })
                .catch(error => {
                    console.error('Error loading ChartJS', error);
                });
        }
    }
}