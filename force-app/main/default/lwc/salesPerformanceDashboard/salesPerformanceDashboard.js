import { LightningElement, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSalesSummary from '@salesforce/apex/SalesPerformanceController.getSalesSummary';
import getTerritorySummary from '@salesforce/apex/SalesPerformanceController.getTerritorySummary';
import getDealVelocity from '@salesforce/apex/SalesPerformanceController.getDealVelocity';

export default class SalesPerformanceDashboard extends LightningElement {
    @track salesSummary;
    @track territorySummary;
    @track dealVelocity;
    @track isLoading = true;
    @track error;
    
    @wire(getSalesSummary)
    wiredSalesSummary({ error, data }) {
        if (data) {
            this.salesSummary = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.salesSummary = undefined;
            this.showToast('Error', 'Error loading sales summary', 'error');
        }
        this.updateLoadingStatus();
    }
    
    @wire(getTerritorySummary)
    wiredTerritorySummary({ error, data }) {
        if (data) {
            this.territorySummary = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.territorySummary = undefined;
            this.showToast('Error', 'Error loading territory summary', 'error');
        }
        this.updateLoadingStatus();
    }
    
    @wire(getDealVelocity)
    wiredDealVelocity({ error, data }) {
        if (data) {
            this.dealVelocity = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.dealVelocity = undefined;
            this.showToast('Error', 'Error loading deal velocity', 'error');
        }
        this.updateLoadingStatus();
    }
    
    updateLoadingStatus() {
        if (this.salesSummary && this.territorySummary && this.dealVelocity) {
            this.isLoading = false;
        }
    }
    
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}