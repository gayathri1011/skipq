import {
  useCallback,
  useEffect,
  useMemo,
  useState,
  type FormEvent,
} from 'react';
import { Link } from 'react-router-dom';
import { Inbox } from 'lucide-react';
import {
  fetchOrderingWindow,
  updateOrderingWindow,
} from '../services/settings';
import { fetchManagerOrders } from '../services/managerOrders';
import { joinManagerRoom } from '../services/socket';
import { fetchDashboardAnalytics } from '../services/analytics';
import type { DashboardAnalytics } from '../types/analytics';
import type { Order } from '../types/order';
import OrderStatusBadge from '../components/OrderStatusBadge';
import { LoadingSpinner } from '../components/ui/UiStates';
import { useAuth } from '../context/AuthContext';
import { useManagerOutlet } from '../layouts/ManagerLayout';
import styles from './ManagerDashboardPage.module.css';

const isTodayIST = (iso: string) => {
  const orderDate = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Kolkata',
  }).format(new Date(iso));
  const today = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Kolkata',
  }).format(new Date());
  return orderDate === today;
};

const formatTime = (iso: string) =>
  new Intl.DateTimeFormat('en-IN', {
    timeStyle: 'short',
    timeZone: 'Asia/Kolkata',
  }).format(new Date(iso));

const ManagerDashboardPage = () => {
  const { user } = useAuth();
  const { setHeaderRefresh } = useManagerOutlet();
  const [orders, setOrders] = useState<Order[]>([]);
  const [openTime, setOpenTime] = useState('09:30');
  const [closeTime, setCloseTime] = useState('11:30');
  const [isOpen, setIsOpen] = useState(true);
  const [settingsMsg, setSettingsMsg] = useState('');
  const [settingsLoading, setSettingsLoading] = useState(false);
  const [settingsReady, setSettingsReady] = useState(false);
  const [ordersLoading, setOrdersLoading] = useState(true);
  const [analytics, setAnalytics] = useState<DashboardAnalytics>({
    totalOrders: 0,
    totalRevenue: 0,
    completedOrders: 0,
    topItems: [],
  });
  const [analyticsRange, setAnalyticsRange] = useState<
    'day' | 'week' | 'month' | 'year' | 'custom'
  >('day');
  const [customStart, setCustomStart] = useState('');
  const [customEnd, setCustomEnd] = useState('');
  const [analyticsLoading, setAnalyticsLoading] = useState(false);

  const loadOrders = useCallback(async () => {
    try {
      const data = await fetchManagerOrders();
      setOrders(data);
    } finally {
      setOrdersLoading(false);
    }
  }, []);

  const loadAnalytics = useCallback(async () => {
    setAnalyticsLoading(true);
    try {
      const data = await fetchDashboardAnalytics({
        range: analyticsRange,
        ...(analyticsRange === 'custom' && customStart
          ? { startDate: customStart }
          : {}),
        ...(analyticsRange === 'custom' && customEnd
          ? { endDate: customEnd }
          : {}),
      });
      setAnalytics(data);
    } finally {
      setAnalyticsLoading(false);
    }
  }, [analyticsRange, customStart, customEnd]);

  useEffect(() => {
    let cancelled = false;

    fetchOrderingWindow()
      .then((data) => {
        if (cancelled) return;
        setOpenTime(data.orderingOpenTime);
        setCloseTime(data.orderingCloseTime);
        setIsOpen(data.isOpen);
      })
      .finally(() => {
        if (!cancelled) setSettingsReady(true);
      });

    loadOrders();

    return () => {
      cancelled = true;
    };
  }, [loadOrders]);

  useEffect(() => {
    const timer = window.setTimeout(() => {
      void loadAnalytics();
    }, 0);
    return () => window.clearTimeout(timer);
  }, [loadAnalytics]);

  useEffect(() => {
    setHeaderRefresh(loadOrders);
    return () => setHeaderRefresh(null);
  }, [loadOrders, setHeaderRefresh]);

  useEffect(() => {
    const socket = joinManagerRoom();

    const handleNewOrder = (order: Order) => {
      setOrders((prev) => {
        const idx = prev.findIndex((o) => o.id === order.id);
        if (idx === -1) return [order, ...prev];
        const next = [...prev];
        next[idx] = order;
        return next;
      });
    };

    socket.on('order:created', handleNewOrder);
    socket.on('order:updated', handleNewOrder);

    return () => {
      socket.off('order:created', handleNewOrder);
      socket.off('order:updated', handleNewOrder);
    };
  }, []);

  const todayOrders = useMemo(
    () => orders.filter((o) => isTodayIST(o.createdAt)),
    [orders],
  );

  const stats = useMemo(() => {
    const pending = todayOrders.filter((o) =>
      ['PENDING', 'CONFIRMED', 'PREPARING'].includes(o.status),
    ).length;
    const ready = todayOrders.filter((o) => o.status === 'READY').length;
    const revenue = todayOrders.reduce((sum, o) => sum + o.total, 0);
    return {
      total: todayOrders.length,
      pending,
      ready,
      revenue,
    };
  }, [todayOrders]);

  const recentOrders = todayOrders.slice(0, 5);

  const handleSaveWindow = async (e: FormEvent) => {
    e.preventDefault();
    setSettingsLoading(true);
    setSettingsMsg('');
    try {
      const data = await updateOrderingWindow(openTime, closeTime);
      setIsOpen(data.isOpen);
      setSettingsMsg('Ordering window updated.');
    } catch {
      setSettingsMsg('Unable to save settings.');
    } finally {
      setSettingsLoading(false);
    }
  };

  const firstName = user?.name?.split(' ')[0] ?? 'Manager';

  return (
    <div className={styles.page}>
      <header className={styles.greetingBlock}>
        <h1 className={styles.greeting}>Hello, {firstName} 👋</h1>
        <p className={styles.greetingSub}>
          Here&apos;s what&apos;s happening today.
        </p>
      </header>

      {ordersLoading ? (
        <LoadingSpinner label="Loading stats…" />
      ) : (
        <div className={styles.statsGrid}>
          <article className={styles.statCard}>
            <span className={styles.statLabel}>Total Orders</span>
            <span className={styles.statValue}>{stats.total}</span>
          </article>
          <article className={styles.statCard}>
            <span className={styles.statLabel}>Pending Orders</span>
            <span className={styles.statValue}>{stats.pending}</span>
          </article>
          <article className={styles.statCard}>
            <span className={styles.statLabel}>Ready Orders</span>
            <span className={styles.statValue}>{stats.ready}</span>
          </article>
          <article className={`${styles.statCard} ${styles.statHighlight}`}>
            <span className={styles.statLabel}>Today&apos;s Revenue</span>
            <span className={styles.statValue}>₹{stats.revenue}</span>
          </article>
        </div>
      )}

      <section className={styles.analyticsCard}>
        <div className={styles.analyticsHeader}>
          <div>
            <h2 className={styles.cardTitle}>Analytics</h2>
            <p className={styles.cardHint}>
              Review sales performance by date range.
            </p>
          </div>
          {analyticsLoading && <LoadingSpinner label="Loading analytics…" />}
        </div>
        <div className={styles.rangeControls}>
          {(['day', 'week', 'month', 'year', 'custom'] as const).map(
            (range) => (
              <button
                key={range}
                type="button"
                className={`${styles.rangeBtn} ${analyticsRange === range ? styles.rangeBtnActive : ''}`}
                onClick={() => setAnalyticsRange(range)}
              >
                {range[0].toUpperCase() + range.slice(1)}
              </button>
            ),
          )}
        </div>
        {analyticsRange === 'custom' && (
          <div className={styles.customDates}>
            <label className={styles.timeField}>
              <span>Start date</span>
              <input
                type="date"
                value={customStart}
                onChange={(e) => setCustomStart(e.target.value)}
              />
            </label>
            <label className={styles.timeField}>
              <span>End date</span>
              <input
                type="date"
                value={customEnd}
                onChange={(e) => setCustomEnd(e.target.value)}
              />
            </label>
          </div>
        )}
        <div className={styles.analyticsGrid}>
          <article className={styles.statCard}>
            <span className={styles.statLabel}>Orders</span>
            <span className={styles.statValue}>{analytics.totalOrders}</span>
          </article>
          <article className={styles.statCard}>
            <span className={styles.statLabel}>Revenue</span>
            <span className={styles.statValue}>₹{analytics.totalRevenue}</span>
          </article>
          <article className={styles.statCard}>
            <span className={styles.statLabel}>Completed</span>
            <span className={styles.statValue}>
              {analytics.completedOrders}
            </span>
          </article>
        </div>
        <h3 className={styles.topItemsTitle}>Top 5 Best Sellers</h3>
        {analytics.topItems.length === 0 ? (
          <p className={styles.cardHint}>No sales data for this range.</p>
        ) : (
          <ol className={styles.topItemsList}>
            {analytics.topItems.map((item) => (
              <li key={item.name}>
                <span>
                  {item.name} · {item.quantity} sold
                </span>
                <strong>₹{item.revenue}</strong>
              </li>
            ))}
          </ol>
        )}
      </section>

      <section className={styles.settingsCard}>
        <h2 className={styles.cardTitle}>Ordering Window</h2>
        {!settingsReady ? (
          <LoadingSpinner label="Loading settings…" />
        ) : (
          <>
            <p className={styles.cardHint}>
              Currently:{' '}
              <strong className={isOpen ? styles.open : styles.closed}>
                {isOpen ? 'Open' : 'Closed'}
              </strong>
            </p>
            <form className={styles.windowForm} onSubmit={handleSaveWindow}>
              <label className={styles.timeField}>
                <span>Open</span>
                <input
                  type="time"
                  value={openTime}
                  onChange={(e) => setOpenTime(e.target.value)}
                  required
                  className={styles.timeInput}
                />
              </label>
              <label className={styles.timeField}>
                <span>Close</span>
                <input
                  type="time"
                  value={closeTime}
                  onChange={(e) => setCloseTime(e.target.value)}
                  required
                  className={styles.timeInput}
                />
              </label>
              <button
                type="submit"
                className={styles.saveBtn}
                disabled={settingsLoading}
              >
                Save
              </button>
            </form>
            {settingsMsg && <p className={styles.settingsMsg}>{settingsMsg}</p>}
          </>
        )}
      </section>

      <section className={styles.recentSection}>
        <h2 className={styles.recentTitle}>Recent Orders</h2>
        {recentOrders.length === 0 ? (
          <div className={styles.emptyFeed}>
            <Inbox size={28} className={styles.emptyFeedIcon} aria-hidden />
            <p className={styles.emptyFeedText}>
              Live orders will appear here as students place them.
            </p>
          </div>
        ) : (
          <ul className={styles.recentList}>
            {recentOrders.map((order) => (
              <li key={order.id} className={styles.recentItem}>
                <div className={styles.recentMain}>
                  <span className={styles.recentToken}>
                    {order.tokenNumber}
                  </span>
                  <span className={styles.recentName}>
                    {order.student?.name ?? 'Student'}
                  </span>
                </div>
                <div className={styles.recentMeta}>
                  <span>
                    {order.items.length} item
                    {order.items.length === 1 ? '' : 's'} ·{' '}
                    {formatTime(order.createdAt)}
                  </span>
                  <OrderStatusBadge status={order.status} />
                </div>
                <span className={styles.recentPayment}>
                  {order.paymentMethod === 'PAY_AT_COUNTER'
                    ? 'Pay at Counter'
                    : 'Paid Online'}
                  {order.paymentStatus === 'PAID' ? ' · Paid' : ' · Pending'}
                </span>
              </li>
            ))}
          </ul>
        )}
      </section>

      <Link to="/manager/orders" className={styles.viewAllBtn}>
        VIEW ALL ORDERS
      </Link>
    </div>
  );
};

export default ManagerDashboardPage;
