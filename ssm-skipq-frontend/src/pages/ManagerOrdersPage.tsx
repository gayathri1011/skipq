import { useEffect, useState } from 'react';
import { ClipboardList, Phone } from 'lucide-react';
import {
  fetchManagerOrders,
  advanceOrderStatus,
  updateOrderPayment,
} from '../services/managerOrders';
import { joinManagerRoom } from '../services/socket';
import type { Order, OrderStatus } from '../types/order';
import OrderStatusBadge from '../components/OrderStatusBadge';
import { OrderCardSkeletonList } from '../components/OrderCardSkeleton';
import { EmptyState } from '../components/ui/UiStates';
import styles from './ManagerOrdersPage.module.css';

const STATUS_ACTION: Partial<Record<OrderStatus, string>> = {
  PENDING: 'Accept',
  CONFIRMED: 'Ready',
  PREPARING: 'Ready',
  READY: 'Collected',
};

const paymentMethodLabel = (method: Order['paymentMethod']) => {
  switch (method) {
    case 'RAZORPAY':
      return 'Razorpay';
    case 'GOOGLE_PAY':
      return 'Google Pay';
    case 'PHONEPE':
      return 'PhonePe';
    case 'PAY_AT_COUNTER':
      return 'Pay at Counter';
    default:
      return method;
  }
};

const ManagerOrdersPage = () => {
  const [orders, setOrders] = useState<Order[]>([]);
  const [pulsingIds, setPulsingIds] = useState<Set<string>>(new Set());
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [callModal, setCallModal] = useState<{
    name: string;
    mobile: string;
  } | null>(null);
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    fetchManagerOrders()
      .then((data) => {
        if (!cancelled) setOrders(data);
      })
      .catch(() => {
        if (!cancelled) setError('Unable to load orders.');
      })
      .finally(() => {
        if (!cancelled) setIsLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    const socket = joinManagerRoom();

    const addPulse = (orderId: string) => {
      setPulsingIds((prev) => new Set(prev).add(orderId));
      setTimeout(() => {
        setPulsingIds((prev) => {
          const next = new Set(prev);
          next.delete(orderId);
          return next;
        });
      }, 2500);
    };

    const upsertOrder = (order: Order) => {
      setOrders((prev) => {
        const idx = prev.findIndex((o) => o.id === order.id);
        if (idx === -1) return [order, ...prev];
        const next = [...prev];
        next[idx] = order;
        return next;
      });
    };

    const handleCreated = (order: Order) => {
      upsertOrder(order);
      addPulse(order.id);
    };

    const handleUpdated = (order: Order) => {
      upsertOrder(order);
    };

    socket.on('order:created', handleCreated);
    socket.on('order:updated', handleUpdated);

    return () => {
      socket.off('order:created', handleCreated);
      socket.off('order:updated', handleUpdated);
    };
  }, []);

  const handleAdvance = async (orderId: string) => {
    setActionLoading(orderId);
    try {
      const updated = await advanceOrderStatus(orderId);
      setOrders((prev) => prev.map((o) => (o.id === updated.id ? updated : o)));
    } catch {
      setError('Unable to update order status.');
    } finally {
      setActionLoading(null);
    }
  };

  const handlePaymentReceived = async (order: Order) => {
    if (order.paymentStatus === 'PAID') return;
    setActionLoading(order.id);
    try {
      const updated = await updateOrderPayment(order.id, 'PAID');
      setOrders((prev) => prev.map((o) => (o.id === updated.id ? updated : o)));
    } catch {
      setError('Unable to update payment status.');
    } finally {
      setActionLoading(null);
    }
  };

  const activeOrders = orders.filter(
    (o) => !['PICKED_UP', 'CANCELLED'].includes(o.status),
  );

  return (
    <div className={styles.page}>
      <p className={styles.subtitle}>
        {activeOrders.length} active · {orders.length} total today
      </p>

      {isLoading && (
        <ul className={styles.list}>
          <OrderCardSkeletonList count={4} />
        </ul>
      )}
      {error && <p className={styles.error}>{error}</p>}

      {!isLoading && !error && orders.length === 0 && (
        <EmptyState
          icon={ClipboardList}
          title="No orders yet"
          message="Waiting for students to place orders. New orders will appear here instantly."
        />
      )}

      {!isLoading && orders.length > 0 && (
        <ul className={styles.list}>
          {orders.map((order) => {
            const nextAction = STATUS_ACTION[order.status];
            const isPulsing = pulsingIds.has(order.id);

            return (
              <li
                key={order.id}
                className={`${styles.card} ${isPulsing ? styles.cardPulse : ''}`}
              >
                <div className={styles.cardHeader}>
                  <span className={styles.token}>{order.tokenNumber}</span>
                  <OrderStatusBadge status={order.status} />
                </div>

                <ul className={styles.items}>
                  {order.items.map((item, idx) => (
                    <li key={`${item.menuItemId}-${idx}`}>
                      {item.name} × {item.quantity}
                    </li>
                  ))}
                </ul>

                <div className={styles.meta}>
                  <span className={styles.total}>₹{order.total}</span>
                  <span className={styles.payment}>
                    {paymentMethodLabel(order.paymentMethod)} ·{' '}
                    {order.paymentStatus === 'PAID' ? 'Paid' : 'Pending'}
                  </span>
                </div>

                {order.status === 'CANCELLED' && (
                  <p className={styles.student}>Cancelled by student</p>
                )}

                {order.student && (
                  <p className={styles.student}>
                    {order.student.name} · {order.student.mobile}
                  </p>
                )}

                <div className={styles.actions}>
                  {nextAction && (
                    <button
                      type="button"
                      className={styles.advanceBtn}
                      disabled={actionLoading === order.id}
                      onClick={() => handleAdvance(order.id)}
                    >
                      {actionLoading === order.id ? '…' : nextAction}
                    </button>
                  )}

                  {order.paymentMethod === 'PAY_AT_COUNTER' &&
                    order.paymentStatus === 'PENDING' && (
                    <button
                      type="button"
                      className={styles.paymentBtn}
                      disabled={actionLoading === order.id}
                      onClick={() => handlePaymentReceived(order)}
                    >
                      Mark Payment Received
                    </button>
                  )}

                  {order.paymentMethod === 'PAY_AT_COUNTER' &&
                    order.paymentStatus === 'PAID' && (
                    <button
                      type="button"
                      className={`${styles.paymentBtn} ${styles.paymentBtnDone}`}
                      disabled
                    >
                      Payment Received ✓
                    </button>
                  )}

                  {order.student && (
                    <>
                      <a
                        href={`tel:${order.student.mobile}`}
                        className={styles.callBtn}
                      >
                        <Phone size={16} />
                        Call Student
                      </a>
                      <button
                        type="button"
                        className={styles.callInfoBtn}
                        onClick={() => setCallModal(order.student!)}
                        title="Show mobile number"
                      >
                        #
                      </button>
                    </>
                  )}
                </div>
              </li>
            );
          })}
        </ul>
      )}

      {callModal && (
        <div
          className={styles.modalBackdrop}
          onClick={() => setCallModal(null)}
          role="presentation"
        >
          <div
            className={styles.modal}
            onClick={(e) => e.stopPropagation()}
            role="dialog"
            aria-labelledby="call-modal-title"
          >
            <h2 id="call-modal-title" className={styles.modalTitle}>
              Call {callModal.name}
            </h2>
            <p className={styles.modalNumber}>{callModal.mobile}</p>
            <a href={`tel:${callModal.mobile}`} className={styles.modalDial}>
              Dial {callModal.mobile}
            </a>
            <button
              type="button"
              className={styles.modalClose}
              onClick={() => setCallModal(null)}
            >
              Close
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default ManagerOrdersPage;
