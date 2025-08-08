// Amazon Link Monitor
// Comprehensive system to track, detect, and fix Amazon link issues

import { validateAmazonLink, fixAmazonUrl, generateFallbackUrls } from './amazonLinkValidator';

export interface LinkMonitorData {
  url: string;
  title: string;
  author: string;
  lastChecked: Date;
  status: 'working' | 'broken' | 'unknown';
  errorCount: number;
  successCount: number;
  lastError?: string;
  fallbackUsed: boolean;
}

export interface LinkHealthReport {
  totalLinks: number;
  workingLinks: number;
  brokenLinks: number;
  unknownLinks: number;
  successRate: number;
  recommendations: string[];
  brokenLinksList: Array<{
    url: string;
    title: string;
    author: string;
    suggestedFix: string;
  }>;
}

class AmazonLinkMonitor {
  private linkData: Map<string, LinkMonitorData> = new Map();
  private isMonitoring = false;
  private checkInterval: NodeJS.Timeout | null = null;

  /**
   * Register a link for monitoring
   */
  registerLink(url: string, title: string, author: string): void {
    const key = this.generateKey(url, title, author);
    
    if (!this.linkData.has(key)) {
      this.linkData.set(key, {
        url,
        title,
        author,
        lastChecked: new Date(),
        status: 'unknown',
        errorCount: 0,
        successCount: 0,
        fallbackUsed: false
      });
    }
  }

  /**
   * Record a successful link access
   */
  recordSuccess(url: string, title: string, author: string): void {
    const key = this.generateKey(url, title, author);
    const data = this.linkData.get(key);
    
    if (data) {
      data.status = 'working';
      data.successCount++;
      data.lastChecked = new Date();
      data.lastError = undefined;
    } else {
      this.registerLink(url, title, author);
      this.recordSuccess(url, title, author);
    }
  }

  /**
   * Record a failed link access
   */
  recordFailure(url: string, title: string, author: string, error?: string): void {
    const key = this.generateKey(url, title, author);
    const data = this.linkData.get(key);
    
    if (data) {
      data.status = 'broken';
      data.errorCount++;
      data.lastChecked = new Date();
      data.lastError = error;
    } else {
      this.registerLink(url, title, author);
      this.recordFailure(url, title, author, error);
    }
  }

  /**
   * Record fallback usage
   */
  recordFallback(url: string, title: string, author: string): void {
    const key = this.generateKey(url, title, author);
    const data = this.linkData.get(key);
    
    if (data) {
      data.fallbackUsed = true;
      data.lastChecked = new Date();
    }
  }

  /**
   * Get health report for all monitored links
   */
  getHealthReport(): LinkHealthReport {
    const links = Array.from(this.linkData.values());
    const totalLinks = links.length;
    const workingLinks = links.filter(l => l.status === 'working').length;
    const brokenLinks = links.filter(l => l.status === 'broken').length;
    const unknownLinks = links.filter(l => l.status === 'unknown').length;
    const successRate = totalLinks > 0 ? (workingLinks / totalLinks) * 100 : 0;

    const brokenLinksList = links
      .filter(l => l.status === 'broken')
      .map(l => ({
        url: l.url,
        title: l.title,
        author: l.author,
        suggestedFix: this.getSuggestedFix(l)
      }));

    const recommendations = this.generateRecommendations(links);

    return {
      totalLinks,
      workingLinks,
      brokenLinks,
      unknownLinks,
      successRate,
      recommendations,
      brokenLinksList
    };
  }

  /**
   * Start automatic monitoring
   */
  startMonitoring(intervalMinutes: number = 60): void {
    if (this.isMonitoring) {
      console.warn('Link monitoring is already active');
      return;
    }

    this.isMonitoring = true;
    this.checkInterval = setInterval(() => {
      this.performHealthCheck();
    }, intervalMinutes * 60 * 1000);

    console.log(`Amazon link monitoring started (checking every ${intervalMinutes} minutes)`);
  }

  /**
   * Stop automatic monitoring
   */
  stopMonitoring(): void {
    if (this.checkInterval) {
      clearInterval(this.checkInterval);
      this.checkInterval = null;
    }
    this.isMonitoring = false;
    console.log('Amazon link monitoring stopped');
  }

  /**
   * Perform a health check on all links
   */
  async performHealthCheck(): Promise<void> {
    console.log('Performing Amazon link health check...');
    
    const links = Array.from(this.linkData.values());
    const promises = links.map(async (link) => {
      try {
        const validation = await validateAmazonLink(link.url);
        
        if (validation.isValid) {
          this.recordSuccess(link.url, link.title, link.author);
        } else {
          this.recordFailure(link.url, link.title, link.author, validation.error);
        }
      } catch (error) {
        this.recordFailure(link.url, link.title, link.author, error instanceof Error ? error.message : 'Unknown error');
      }
    });

    await Promise.allSettled(promises);
    
    const report = this.getHealthReport();
    console.log('Health check completed:', {
      totalLinks: report.totalLinks,
      workingLinks: report.workingLinks,
      brokenLinks: report.brokenLinks,
      successRate: `${report.successRate.toFixed(1)}%`
    });

    // Log broken links for immediate attention
    if (report.brokenLinks > 0) {
      console.warn('Broken Amazon links detected:', report.brokenLinksList);
    }
  }

  /**
   * Get suggested fix for a broken link
   */
  private getSuggestedFix(link: LinkMonitorData): string {
    if (link.url.includes('amzn.eu') || link.url.includes('amzn.to')) {
      return `Convert shortened URL to direct product link: ${fixAmazonUrl(link.url)}`;
    }
    
    if (link.errorCount > 3) {
      return `Replace with search URL: ${generateFallbackUrls(link.title, link.author)[0]}`;
    }
    
    return 'Check if product is still available on Amazon';
  }

  /**
   * Generate recommendations based on link health
   */
  private generateRecommendations(links: LinkMonitorData[]): string[] {
    const recommendations: string[] = [];
    
    const brokenLinks = links.filter(l => l.status === 'broken');
    const shortenedLinks = links.filter(l => l.url.includes('amzn.eu') || l.url.includes('amzn.to'));
    const highErrorLinks = links.filter(l => l.errorCount > 3);
    
    if (brokenLinks.length > 0) {
      recommendations.push(`Fix ${brokenLinks.length} broken Amazon links`);
    }
    
    if (shortenedLinks.length > 0) {
      recommendations.push(`Convert ${shortenedLinks.length} shortened URLs to direct product links`);
    }
    
    if (highErrorLinks.length > 0) {
      recommendations.push(`Replace ${highErrorLinks.length} frequently failing links with search URLs`);
    }
    
    const successRate = links.length > 0 ? 
      (links.filter(l => l.status === 'working').length / links.length) * 100 : 0;
    
    if (successRate < 90) {
      recommendations.push('Overall link health is below 90% - consider comprehensive review');
    }
    
    return recommendations;
  }

  /**
   * Generate a unique key for link tracking
   */
  private generateKey(url: string, title: string, author: string): string {
    return `${url}-${title}-${author}`.toLowerCase().replace(/[^a-z0-9-]/g, '-');
  }

  /**
   * Export monitoring data for analysis
   */
  exportData(): LinkMonitorData[] {
    return Array.from(this.linkData.values());
  }

  /**
   * Clear old monitoring data
   */
  clearOldData(daysOld: number = 30): void {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysOld);
    
    for (const [key, data] of this.linkData.entries()) {
      if (data.lastChecked < cutoffDate) {
        this.linkData.delete(key);
      }
    }
    
    console.log(`Cleared monitoring data older than ${daysOld} days`);
  }
}

// Create a singleton instance
export const amazonLinkMonitor = new AmazonLinkMonitor();

// Auto-start monitoring in development
if (import.meta.env.DEV) {
  amazonLinkMonitor.startMonitoring(30); // Check every 30 minutes in development
}
