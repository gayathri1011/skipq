import { api } from './api';
import type {
  CreateOrderPayload,
  Order,
  OrderResponse,
  OrdersResponse,
} from '../types/order';

export const fetchMyOrders = async () => {
  const { data } = await api.get<OrdersResponse>('/orders');
  return data.data.orders;
};

export const fetchOrder = async (orderId: string) => {
  const { data } = await api.get<{ success: boolean; data: { order: Order } }>(
    `/orders/${orderId}`,
  );
  return data.data.order;
};

export const cancelOrder = async (orderId: string) => {
  const { data } = await api.patch<{ success: boolean; data: { order: Order } }>(
    `/orders/${orderId}/cancel`,
  );
  return data.data.order;
};

export const createOrder = async (payload: CreateOrderPayload) => {
  const { data } = await api.post<OrderResponse>('/orders', payload);
  return data.data;
};
