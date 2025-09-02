import { validateAmazonLink, fixAmazonUrl, generateAmazonSearchUrl } from './amazonLinkValidator';

export interface BrokenLinkReport {
  file: string;
  bookTitle: string;
  bookAuthor: string;
  originalLink: string;
  issue: string;
  suggestedFix: string;
  status: 'broken' | 'working' | 'needs_verification';
}

export interface LinkHealthSummary {
  totalLinks: number;
  workingLinks: number;
  brokenLinks: number;
  needsVerification: number;
  brokenLinksList: BrokenLinkReport[];
}

/**
 * Comprehensive Amazon link checker for all book data in the app
 */
export class AmazonLinkChecker {
  private static instance: AmazonLinkChecker;
  private checkedLinks = new Map<string, BrokenLinkReport>();

  static getInstance(): AmazonLinkChecker {
    if (!AmazonLinkChecker.instance) {
      AmazonLinkChecker.instance = new AmazonLinkChecker();
    }
    return AmazonLinkChecker.instance;
  }

  /**
   * Check all Amazon links in the trending books data
   */
  async checkTrendingBooks(): Promise<BrokenLinkReport[]> {
    const { trendingBooks } = await import('../data/trendingBooks');
    const reports: BrokenLinkReport[] = [];

    for (const book of trendingBooks) {
      const report = await this.checkSingleLink(
        'trendingBooks.ts',
        book.title,
        book.author,
        book.amazonLink
      );
      if (report) {
        reports.push(report);
      }
    }

    return reports;
  }

  /**
   * Check all Amazon links in the celebrities data
   */
  async checkCelebrities(): Promise<BrokenLinkReport[]> {
    const { celebrities } = await import('../data/celebrities');
    const reports: BrokenLinkReport[] = [];

    for (const celebrity of celebrities) {
      for (const book of celebrity.bookRecommendations) {
        const report = await this.checkSingleLink(
          'celebrities.ts',
          book.title,
          book.author,
          book.amazonLink
        );
        if (report) {
          report.file = `celebrities.ts (${celebrity.name})`;
          if (report) {
            reports.push(report);
          }
        }
      }
    }

    return reports;
  }

  /**
   * Check all Amazon links in the book recommendations optimized data
   */
  async checkBookRecommendations(): Promise<BrokenLinkReport[]> {
    const { getBookRecommendations } = await import('./bookRecommendationsOptimized');
    const reports: BrokenLinkReport[] = [];

    // Create a mock profile to get all books
    const mockProfile = {
      openness: 15,
      conscientiousness: 15,
      extraversion: 15,
      agreeableness: 15,
      emotionalStability: 15,
      rationalThinking: 15,
      coreValues: 15,
      lifestyle: 15,
      socialStyle: 15,
      selfExpression: 15
    };

    // Get a sample of books to check (this will include most of the curated books)
    const sampleBooks = getBookRecommendations(mockProfile, [], true);
    
    for (const book of sampleBooks) {
      const report = await this.checkSingleLink(
        'bookRecommendationsOptimized.ts',
        book.title,
        book.author,
        book.amazonLink
      );
      if (report) {
        reports.push(report);
      }
    }

    return reports;
  }

  /**
   * Check a single Amazon link and return a report if there are issues
   */
  private async checkSingleLink(
    file: string,
    title: string,
    author: string,
    link: string
  ): Promise<BrokenLinkReport | null> {
    const cacheKey = `${file}-${title}-${author}`;
    
    // Check cache first
    if (this.checkedLinks.has(cacheKey)) {
      return this.checkedLinks.get(cacheKey)!;
    }

    try {
      // Validate the link
      const validation = await validateAmazonLink(link);
      
      let report: BrokenLinkReport | null = null;

      if (!validation.isValid) {
        // Link is broken or has issues
        const suggestedFix = this.generateSuggestedFix(title, author, link);
        
        report = {
          file,
          bookTitle: title,
          bookAuthor: author,
          originalLink: link,
          issue: validation.error || 'Link validation failed',
          suggestedFix,
          status: 'broken'
        };
      } else if (link.includes('amzn.eu') || link.includes('amzn.to')) {
        // Link is shortened - suggest direct product link
        const suggestedFix = this.generateSuggestedFix(title, author, link);
        
        report = {
          file,
          bookTitle: title,
          bookAuthor: author,
          originalLink: link,
          issue: 'Shortened Amazon URL (less reliable)',
          suggestedFix,
          status: 'needs_verification'
        };
      } else if (!link.includes('/dp/') && !link.includes('/gp/product/')) {
        // Link is not a direct product link
        const suggestedFix = this.generateSuggestedFix(title, author, link);
        
        report = {
          file,
          bookTitle: title,
          bookAuthor: author,
          originalLink: link,
          issue: 'Not a direct product link (may be less reliable)',
          suggestedFix,
          status: 'needs_verification'
        };
      }

      // Cache the result
      if (report) {
        this.checkedLinks.set(cacheKey, report);
      }

      return report;
    } catch (error) {
      // Error occurred during validation
      const suggestedFix = this.generateSuggestedFix(title, author, link);
      
      const report: BrokenLinkReport = {
        file,
        bookTitle: title,
        bookAuthor: author,
        originalLink: link,
        issue: `Validation error: ${error instanceof Error ? error.message : 'Unknown error'}`,
        suggestedFix,
        status: 'broken'
      };

      this.checkedLinks.set(cacheKey, report);
      return report;
    }
  }

  /**
   * Generate a suggested fix for a broken or problematic link
   */
  private generateSuggestedFix(title: string, author: string, originalLink: string): string {
    // Try to extract product ID from various Amazon URL formats
    const productId = this.extractProductId(originalLink);
    
    if (productId) {
      return `https://www.amazon.co.uk/dp/${productId}`;
    }
    
    // Fallback to search URL
    return generateAmazonSearchUrl(title, author);
  }

  /**
   * Extract product ID from various Amazon URL formats
   */
  private extractProductId(url: string): string | null {
    const patterns = [
      /amazon\.co\.uk\/dp\/([A-Z0-9]{10})/,
      /amazon\.co\.uk\/gp\/product\/([A-Z0-9]{10})/,
      /amzn\.eu\/d\/([A-Za-z0-9]+)/,
      /amzn\.to\/([A-Za-z0-9]+)/,
      /amazon\.co\.uk\/[^\/]+\/dp\/([A-Z0-9]{10})/
    ];
    
    for (const pattern of patterns) {
      const match = url.match(pattern);
      if (match) {
        return match[1];
      }
    }
    
    return null;
  }

  /**
   * Get a comprehensive health report for all Amazon links
   */
  async getComprehensiveHealthReport(): Promise<LinkHealthSummary> {
    const [trendingReports, celebrityReports, recommendationReports] = await Promise.all([
      this.checkTrendingBooks(),
      this.checkCelebrities(),
      this.checkBookRecommendations()
    ]);

    const allReports = [...trendingReports, ...celebrityReports, ...recommendationReports];
    
    const workingLinks = allReports.filter(r => r.status === 'working').length;
    const brokenLinks = allReports.filter(r => r.status === 'broken').length;
    const needsVerification = allReports.filter(r => r.status === 'needs_verification').length;

    return {
      totalLinks: allReports.length,
      workingLinks,
      brokenLinks,
      needsVerification,
      brokenLinksList: allReports.filter(r => r.status !== 'working')
    };
  }

  /**
   * Generate a markdown report of all broken links
   */
  async generateMarkdownReport(): Promise<string> {
    const healthReport = await this.getComprehensiveHealthReport();
    
    let markdown = `# Amazon Links Health Report\n\n`;
    markdown += `Generated on: ${new Date().toISOString()}\n\n`;
    
    markdown += `## Summary\n\n`;
    markdown += `- **Total Links Checked:** ${healthReport.totalLinks}\n`;
    markdown += `- **Working Links:** ${healthReport.workingLinks}\n`;
    markdown += `- **Broken Links:** ${healthReport.brokenLinks}\n`;
    markdown += `- **Needs Verification:** ${healthReport.needsVerification}\n\n`;
    
    if (healthReport.brokenLinksList.length > 0) {
      markdown += `## Broken Links Requiring Fixes\n\n`;
      
      // Group by file
      const groupedByFile = this.groupReportsByFile(healthReport.brokenLinksList);
      
      for (const [file, reports] of Object.entries(groupedByFile)) {
        markdown += `### ${file}\n\n`;
        
        for (const report of reports) {
          markdown += `#### ${report.bookTitle} by ${report.bookAuthor}\n\n`;
          markdown += `- **Original Link:** ${report.originalLink}\n`;
          markdown += `- **Issue:** ${report.issue}\n`;
          markdown += `- **Suggested Fix:** ${report.suggestedFix}\n\n`;
        }
      }
    }
    
    return markdown;
  }

  /**
   * Group broken link reports by file
   */
  private groupReportsByFile(reports: BrokenLinkReport[]): Record<string, BrokenLinkReport[]> {
    return reports.reduce((acc, report) => {
      if (!acc[report.file]) {
        acc[report.file] = [];
      }
      acc[report.file].push(report);
      return acc;
    }, {} as Record<string, BrokenLinkReport[]>);
  }

  /**
   * Clear the cache
   */
  clearCache(): void {
    this.checkedLinks.clear();
  }
}

export const amazonLinkChecker = AmazonLinkChecker.getInstance();
