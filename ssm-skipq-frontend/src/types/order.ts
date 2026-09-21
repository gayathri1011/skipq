export type PaymentMethod = 'GOOGLE_PAY' | 'PHONEPE' | 'PAY_AT_COUNTER' | 'RAZORPAY';
export type PaymentStatus = 'PENDING' | 'PAID';
export type OrderStatus =
  'PENDING' | 'CONFIRMED' | 'PREPARING' | 'READY' | 'PICKED_UP' | 'CANCELLED';

export interface OrderItem {
  menuItemId: string;
  name: string;
  price: number;
  quantity: number;
}

export interface OrderStudent {
  name: string;
  mobile: string;
}

export interface Order {
  id: string;
  studentId: string;
  student?: OrderStudent;
  items: OrderItem[];
  total: number;
  paymentMethod: PaymentMethod;
  paymentStatus: PaymentStatus;
  status: OrderStatus;
  cancelledBy?: 'STUDENT';
  tokenNumber: string;
  createdAt: string;
  hasFeedback?: boolean;
}

export interface CreateOrderPayload {
  items: OrderItem[];
  total: number;
  paymentMethod: PaymentMethod;
  paymentStatus: PaymentStatus;
}

export interface OrdersResponse {
  success: boolean;
  data: { orders: Order[] };
}

export interface OrderResponse {
  success: boolean;
  data: {
    order: Order;
    razorpay?: {
      orderId: string;
      keyId: string;
      amount: number;
      currency: string;
      testMode: boolean;
    } | null;
  };
}
