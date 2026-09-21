export interface DashboardTopItem {
  name: string;
  quantity: number;
  revenue: number;
}

export interface DashboardAnalytics {
  totalOrders: number;
  totalRevenue: number;
  completedOrders: number;
  topItems: DashboardTopItem[];
}
