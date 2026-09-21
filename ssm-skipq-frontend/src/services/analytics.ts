import { api } from './api';
import type { DashboardAnalytics } from '../types/analytics';

interface AnalyticsResponse {
  success: boolean;
  data: { analytics: DashboardAnalytics };
}

export const fetchDashboardAnalytics = async (params: {
  range: 'day' | 'week' | 'month' | 'year' | 'custom';
  startDate?: string;
  endDate?: string;
}) => {
  const { data } = await api.get<AnalyticsResponse>('/orders/analytics', {
    params,
  });
  return data.data.analytics;
};
