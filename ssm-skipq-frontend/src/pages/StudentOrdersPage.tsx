import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ClipboardList, RotateCcw } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useCart } from '../context/CartContext';
import { useToast } from '../context/ToastContext';
import { fetchMyOrders } from '../services/orders';
import { fetchMenuItems } from '../services/menu';
import { joinStudentRoom } from '../services/socket';
import { resolveReorderLines } from '../utils/reorder';
import type { Order } from '../types/order';
import OrderStatusBadge from '../components/OrderStatusBadge';
import OrderFeedbackForm from '../components/OrderFeedbackForm';
import { OrderCardSkeletonList } from '../components/OrderCardSkeleton';
import { EmptyState } from '../components/ui/UiStates';
import PageHeader from '../components/PageHeader';
import formStyles from '../components/OrderFeedbackForm.module.css';
import styles from './StudentOrdersPage.module.css';

const formatDate = (iso: string) => {
  return new Intl.DateTimeFormat('en-IN', {
    dateStyle: 'medium',
    timeStyle: 'short',
    timeZone: 'Asia/Kolkata',
  }).format(new Date(iso));
};

const paymentLabel = (method: Order['paymentMethod']) => {
  switch (method) {
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

const StudentOrdersPage = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const { addItemWithQuantity } = useCart();
  const { addToast } = useToast();
  const [orders, setOrders] = useState<Order[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [reorderingId, setReorderingId] = useState<string | null>(null);
  const [submittedFeedbackIds, setSubmittedFeedbackIds] = useState<Set<string>>(
    new Set(),
  );

  const markFeedbackSubmitted = (orderId: string) => {
    setSubmittedFeedbackIds((prev) => new Set(prev).add(orderId));
    setOrders((prev) =>
      prev.map((order) =>
        order.id === orderId ? { ...order, hasFeedback: true } : order,
      ),
    );
  };

  const needsFeedback = (order: Order) =>
    order.status === 'PICKED_UP' &&
    !order.hasFeedback &&
    !submittedFeedbackIds.has(order.id);

  const handleReorder = async (order: Order) => {
    if (order.status === 'CANCELLED') return;

    setReorderingId(order.id);
    try {
      const menuItems = await fetchMenuItems();
      const { lines, skippedCount } = resolveReorderLines(
        order.items,
        menuItems,
      );

      if (lines.length === 0) {
        addToast({
          variant: 'student',
          title: 'Nothing to reorder',
          message:
            skippedCount > 0
              ? `${skippedCount} item${skippedCount === 1 ? '' : 's'} from this order are no longer available.`
              : 'This order has no items to add.',
        });
        return;
      }

      for (const { menuItem, quantity } of lines) {
        addItemWithQuantity(
          {
            menuItemId: menuItem.id,
            name: menuItem.name,
            price: menuItem.price,
            imageUrl: menuItem.imageUrl,
            isVeg: menuItem.isVeg,
            available: menuItem.available,
          },
          quantity,
        );
      }

      if (skippedCount > 0) {
        addToast({
          variant: 'student',
          title: 'Some items skipped',
          message: `${skippedCount} item${skippedCount === 1 ? '' : 's'} from this order are no longer available and were skipped`,
        });
      }

      navigate('/student/cart');
    } catch {
      addToast({
        variant: 'student',
        title: 'Reorder failed',
        message: 'Unable to load the menu. Please try again.',
      });
    } finally {
      setReorderingId(null);
    }
  };

  useEffect(() => {
    let cancelled = false;

    fetchMyOrders()
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
    if (!user || user.role !== 'student') return;

    const socket = joinStudentRoom();

    const handleUpdate = (updated: Order) => {
      setOrders((prev) => {
        const index = prev.findIndex((o) => o.id === updated.id);
        if (index === -1) {
          return [updated, ...prev];
        }
        const next = [...prev];
        next[index] = updated;
        return next;
      });
    };

    socket.on('order:updated', handleUpdate);

    return () => {
      socket.off('order:updated', handleUpdate);
    };
  }, [user]);

  if (user?.role !== 'student') return null;

  return (
    <div className={styles.page}>
      <PageHeader title="Your Orders" backTo="/student" />

      <div className={styles.body}>
        {isLoading && (
          <ul className={styles.list}>
            <OrderCardSkeletonList count={3} />
          </ul>
        )}
        {error && <p className={styles.error}>{error}</p>}

        {!isLoading && !error && orders.length === 0 && (
          <EmptyState
            icon={ClipboardList}
            title="No orders yet"
            message="Place your first order from the menu — it'll show up here with live status updates."
            actionLabel="Browse Menu"
            actionTo="/student"
          />
        )}

        {!isLoading && !error && orders.length > 0 && (
          <ul className={styles.list}>
            {orders.map((order) => (
              <li
                key={order.id}
                className={styles.card}
                role="button"
                tabIndex={0}
                onClick={() => navigate(`/student/track-order/${order.id}`, { state: { order } })}
                onKeyDown={(event) => {
                  if (event.key === 'Enter' || event.key === ' ') {
                    event.preventDefault();
                    navigate(`/student/track-order/${order.id}`, { state: { order } });
                  }
                }}
              >
                <div className={styles.cardHeader}>
                  <div>
                    <span className={styles.token}>{order.tokenNumber}</span>
                    <span className={styles.date}>
                      {formatDate(order.createdAt)}
                    </span>
                  </div>
                  <OrderStatusBadge status={order.status} />
                </div>

                <ul className={styles.items}>
                  {order.items.map((item, idx) => (
                    <li key={`${item.menuItemId}-${idx}`}>
                      {item.name} × {item.quantity}
                    </li>
                  ))}
                </ul>

                <div className={styles.cardFooter}>
                  <span>₹{order.total}</span>
                  <span className={styles.payment}>
                    {paymentLabel(order.paymentMethod)}
                    {order.paymentStatus === 'PAID' ? ' · Paid' : ' · Pending'}
                  </span>
                </div>

                {order.status !== 'CANCELLED' && (
                  <button
                    type="button"
                    className={styles.reorderBtn}
                    onClick={(event) => {
                      event.stopPropagation();
                      void handleReorder(order);
                    }}
                    disabled={reorderingId === order.id}
                  >
                    <RotateCcw size={16} />
                    {reorderingId === order.id ? 'Adding…' : 'Reorder'}
                  </button>
                )}

                {needsFeedback(order) && (
                  <div onClick={(event) => event.stopPropagation()}>
                    <OrderFeedbackForm
                      orderId={order.id}
                      tokenNumber={order.tokenNumber}
                      onSubmitted={() => markFeedbackSubmitted(order.id)}
                    />
                  </div>
                )}

                {order.status === 'PICKED_UP' &&
                  (order.hasFeedback || submittedFeedbackIds.has(order.id)) && (
                    <p className={formStyles.thankYou}>
                      Thanks for your feedback!
                    </p>
                  )}
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
};

export default StudentOrdersPage;
