import React, { useState, useEffect } from 'react';
import { bookCoverService } from '../services/bookCoverService';
import { TrendingUp, Clock, Database, AlertTriangle, CheckCircle } from 'lucide-react';

interface PerformanceMetrics {
  totalRequests: number;
  cacheHits: number;
  apiCalls: number;
  averageResponseTime: number;
  errors: number;
}

interface RateLimitStatus {
  google: { current: number; limit: number };
  openlibrary: { current: number; limit: number };
}

export const BookCoverPerformanceMonitor: React.FC = () => {
  const [metrics, setMetrics] = useState<PerformanceMetrics>({
    totalRequests: 0,
    cacheHits: 0,
    apiCalls: 0,
    averageResponseTime: 0,
    errors: 0
  });
  
  const [rateLimits, setRateLimits] = useState<RateLimitStatus>({
    google: { current: 0, limit: 2000 },
    openlibrary: { current: 0, limit: 10000 }
  });
  
  const [isVisible, setIsVisible] = useState(false);
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date());

  useEffect(() => {
    const updateMetrics = () => {
      const cacheStats = bookCoverService.getCacheStats();
      const rateLimitStatus = bookCoverService.getRateLimitStatus();
      
      setMetrics(prev => ({
        ...prev,
        apiCalls: cacheStats.apiCalls
      }));
      
      setRateLimits(rateLimitStatus);
      setLastUpdate(new Date());
    };

    // Update every 5 seconds
    const interval = setInterval(updateMetrics, 5000);
    updateMetrics(); // Initial update

    return () => clearInterval(interval);
  }, []);

  const cacheHitRate = metrics.totalRequests > 0 ? (metrics.cacheHits / metrics.totalRequests * 100).toFixed(1) : '0';
  const errorRate = metrics.totalRequests > 0 ? (metrics.errors / metrics.totalRequests * 100).toFixed(1) : '0';
  const avgResponseTime = metrics.averageResponseTime > 0 ? metrics.averageResponseTime.toFixed(0) : '0';

  const getPerformanceStatus = () => {
    if (cacheHitRate >= '80' && errorRate <= '5') return 'excellent';
    if (cacheHitRate >= '60' && errorRate <= '10') return 'good';
    if (cacheHitRate >= '40' && errorRate <= '15') return 'fair';
    return 'poor';
  };

  const getRateLimitStatus = (current: number, limit: number) => {
    const percentage = (current / limit) * 100;
    if (percentage >= 90) return 'critical';
    if (percentage >= 75) return 'warning';
    if (percentage >= 50) return 'moderate';
    return 'good';
  };

  const performanceStatus = getPerformanceStatus();

  return (
    <div className="fixed bottom-4 right-4 z-50">
      {/* Toggle Button */}
      <button
        onClick={() => setIsVisible(!isVisible)}
        className="bg-gradient-to-r from-amber-500 to-orange-600 text-white p-3 rounded-full shadow-lg hover:from-amber-600 hover:to-orange-700 transition-all duration-300"
        title="Performance Monitor"
      >
        <TrendingUp className="w-5 h-5" />
      </button>

      {/* Performance Panel */}
      {isVisible && (
        <div className="absolute bottom-16 right-0 w-80 bg-black/90 backdrop-blur-xl border border-white/20 rounded-xl p-4 shadow-2xl">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-white font-semibold text-lg">Book Cover Performance</h3>
            <div className={`w-3 h-3 rounded-full ${
              performanceStatus === 'excellent' ? 'bg-green-500' :
              performanceStatus === 'good' ? 'bg-yellow-500' :
              performanceStatus === 'fair' ? 'bg-orange-500' : 'bg-red-500'
            }`} />
          </div>

          {/* Performance Metrics */}
          <div className="space-y-3">
            {/* Cache Hit Rate */}
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <Database className="w-4 h-4 text-blue-400" />
                <span className="text-white/80 text-sm">Cache Hit Rate</span>
              </div>
              <span className={`font-semibold ${
                parseFloat(cacheHitRate) >= 80 ? 'text-green-400' :
                parseFloat(cacheHitRate) >= 60 ? 'text-yellow-400' :
                parseFloat(cacheHitRate) >= 40 ? 'text-orange-400' : 'text-red-400'
              }`}>
                {cacheHitRate}%
              </span>
            </div>

            {/* Average Response Time */}
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <Clock className="w-4 h-4 text-purple-400" />
                <span className="text-white/80 text-sm">Avg Response</span>
              </div>
              <span className={`font-semibold ${
                parseFloat(avgResponseTime) <= 1000 ? 'text-green-400' :
                parseFloat(avgResponseTime) <= 2000 ? 'text-yellow-400' :
                parseFloat(avgResponseTime) <= 3000 ? 'text-orange-400' : 'text-red-400'
              }`}>
                {avgResponseTime}ms
              </span>
            </div>

            {/* Error Rate */}
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <AlertTriangle className="w-4 h-4 text-red-400" />
                <span className="text-white/80 text-sm">Error Rate</span>
              </div>
              <span className={`font-semibold ${
                parseFloat(errorRate) <= 5 ? 'text-green-400' :
                parseFloat(errorRate) <= 10 ? 'text-yellow-400' :
                parseFloat(errorRate) <= 15 ? 'text-orange-400' : 'text-red-400'
              }`}>
                {errorRate}%
              </span>
            </div>

            {/* API Calls */}
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <TrendingUp className="w-4 h-4 text-green-400" />
                <span className="text-white/80 text-sm">API Calls</span>
              </div>
              <span className="text-white font-semibold">{metrics.apiCalls}</span>
            </div>
          </div>

          {/* Rate Limits */}
          <div className="mt-4 pt-4 border-t border-white/10">
            <h4 className="text-white/90 font-medium text-sm mb-3">Rate Limits</h4>
            
            {/* Google Books API */}
            <div className="mb-2">
              <div className="flex items-center justify-between mb-1">
                <span className="text-white/70 text-xs">Google Books</span>
                <span className={`text-xs font-medium ${
                  getRateLimitStatus(rateLimits.google.current, rateLimits.google.limit) === 'critical' ? 'text-red-400' :
                  getRateLimitStatus(rateLimits.google.current, rateLimits.google.limit) === 'warning' ? 'text-yellow-400' :
                  getRateLimitStatus(rateLimits.google.current, rateLimits.google.limit) === 'moderate' ? 'text-orange-400' : 'text-green-400'
                }`}>
                  {rateLimits.google.current}/{rateLimits.google.limit}
                </span>
              </div>
              <div className="w-full bg-white/10 rounded-full h-1.5">
                <div 
                  className={`h-1.5 rounded-full transition-all duration-300 ${
                    getRateLimitStatus(rateLimits.google.current, rateLimits.google.limit) === 'critical' ? 'bg-red-500' :
                    getRateLimitStatus(rateLimits.google.current, rateLimits.google.limit) === 'warning' ? 'bg-yellow-500' :
                    getRateLimitStatus(rateLimits.google.current, rateLimits.google.limit) === 'moderate' ? 'bg-orange-500' : 'bg-green-500'
                  }`}
                  style={{ width: `${Math.min((rateLimits.google.current / rateLimits.google.limit) * 100, 100)}%` }}
                />
              </div>
            </div>

            {/* Open Library API */}
            <div className="mb-2">
              <div className="flex items-center justify-between mb-1">
                <span className="text-white/70 text-xs">Open Library</span>
                <span className={`text-xs font-medium ${
                  getRateLimitStatus(rateLimits.openlibrary.current, rateLimits.openlibrary.limit) === 'critical' ? 'text-red-400' :
                  getRateLimitStatus(rateLimits.openlibrary.current, rateLimits.openlibrary.limit) === 'warning' ? 'text-yellow-400' :
                  getRateLimitStatus(rateLimits.openlibrary.current, rateLimits.openlibrary.limit) === 'moderate' ? 'text-orange-400' : 'text-green-400'
                }`}>
                  {rateLimits.openlibrary.current}/{rateLimits.openlibrary.limit}
                </span>
              </div>
              <div className="w-full bg-white/10 rounded-full h-1.5">
                <div 
                  className={`h-1.5 rounded-full transition-all duration-300 ${
                    getRateLimitStatus(rateLimits.openlibrary.current, rateLimits.openlibrary.limit) === 'critical' ? 'bg-red-500' :
                    getRateLimitStatus(rateLimits.openlibrary.current, rateLimits.openlibrary.limit) === 'warning' ? 'bg-yellow-500' :
                    getRateLimitStatus(rateLimits.openlibrary.current, rateLimits.openlibrary.limit) === 'moderate' ? 'bg-orange-500' : 'bg-green-500'
                  }`}
                  style={{ width: `${Math.min((rateLimits.openlibrary.current / rateLimits.openlibrary.limit) * 100, 100)}%` }}
                />
              </div>
            </div>
          </div>

          {/* Status Summary */}
          <div className="mt-4 pt-4 border-t border-white/10">
            <div className="flex items-center justify-between">
              <span className="text-white/70 text-xs">Status</span>
              <div className="flex items-center space-x-1">
                {performanceStatus === 'excellent' && <CheckCircle className="w-3 h-3 text-green-400" />}
                {performanceStatus === 'good' && <CheckCircle className="w-3 h-3 text-yellow-400" />}
                {performanceStatus === 'fair' && <AlertTriangle className="w-3 h-3 text-orange-400" />}
                {performanceStatus === 'poor' && <AlertTriangle className="w-3 h-3 text-red-400" />}
                <span className={`text-xs font-medium capitalize ${
                  performanceStatus === 'excellent' ? 'text-green-400' :
                  performanceStatus === 'good' ? 'text-yellow-400' :
                  performanceStatus === 'fair' ? 'text-orange-400' : 'text-red-400'
                }`}>
                  {performanceStatus}
                </span>
              </div>
            </div>
          </div>

          {/* Last Update */}
          <div className="mt-2 text-center">
            <span className="text-white/50 text-xs">
              Last update: {lastUpdate.toLocaleTimeString()}
            </span>
          </div>
        </div>
      )}
    </div>
  );
};

export default BookCoverPerformanceMonitor;
