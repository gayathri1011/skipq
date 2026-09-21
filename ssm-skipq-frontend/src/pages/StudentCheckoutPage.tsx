import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import axios from 'axios';
import {
  CreditCard,
  Loader2,
  ShieldCheck,
  Store,
  UtensilsCrossed,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useCart } from '../context/CartContext';
import { createOrder } from '../services/orders';
import {
  fetchPaymentConfig,
  openRazorpayCheckout,
  verifyRazorpayPayment,
  type PaymentConfig,
} from '../services/payments';
import PageHeader from '../components/PageHeader';
import type { PaymentMethod } from '../types/order';
import styles from './StudentCheckoutPage.module.css';

const PACKAGING_CHARGE = 0;

const StudentCheckoutPage = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { items, totalAmount, clear } = useCart();
  const [selectedMethod, setSelectedMethod] =
    useState<PaymentMethod>('RAZORPAY');
  const [paymentConfig, setPaymentConfig] = useState<PaymentConfig | null>(null);
  const [loadingConfig, setLoadingConfig] = useState(true);
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchPaymentConfig()
      .then((config) => {
        setPaymentConfig(config);
        setSelectedMethod(config.enabled ? 'RAZORPAY' : 'PAY_AT_COUNTER');
      })
      .catch(() => {
        setPaymentConfig({ enabled: false, keyId: '', testMode: false });
        setSelectedMethod('PAY_AT_COUNTER');
      })
      .finally(() => setLoadingConfig(false));
  }, []);

  if (items.length === 0 && !isProcessing) {
    navigate('/student/cart', { replace: true });
    return null;
  }

  const subtotal = totalAmount;
  const total = subtotal + PACKAGING_CHARGE;
  const razorpayEnabled = paymentConfig?.enabled ?? false;
  const testMode = paymentConfig?.testMode ?? false;

  const handleConfirm = async () => {
    setError('');
    setIsProcessing(true);

    try {
      const result = await createOrder({
        items: items.map((item) => ({
          menuItemId: item.menuItemId,
          name: item.name,
          price: item.price,
          quantity: item.quantity,
        })),
        total: subtotal,
        paymentMethod: selectedMethod,
        paymentStatus: selectedMethod === 'PAY_AT_COUNTER' ? 'PENDING' : 'PENDING',
      });

      let finalOrder = result.order;

      if (selectedMethod === 'RAZORPAY') {
        if (!result.razorpay) {
          throw new Error('Razorpay checkout was not returned by the server');
        }

        const payment = await openRazorpayCheckout({
          checkout: result.razorpay,
          skipqOrderId: result.order.id,
          customerName: user?.name ?? 'Student',
          customerMobile: user?.role === 'student' ? user.mobile : '',
          description: `SkipQ order ${result.order.tokenNumber}`,
        });

        finalOrder = await verifyRazorpayPayment({
          orderId: result.order.id,
          razorpayOrderId: payment.razorpayOrderId,
          razorpayPaymentId: payment.razorpayPaymentId,
          razorpaySignature: payment.razorpaySignature,
        });
      }

      clear();
      navigate(`/student/track-order/${finalOrder.id}`, {
        replace: true,
        state: { order: finalOrder },
      });
    } catch (err) {
      const message =
        err instanceof Error
          ? err.message
          : axios.isAxiosError(err) && err.response?.data?.message
            ? err.response.data.message
            : 'Unable to place order. Please try again.';
      setError(message);
      setIsProcessing(false);
    }
  };

  return (
    <div className={styles.page}>
      <PageHeader title="Checkout" backTo="/student/cart" />

      <div className={styles.body}>
        <section className={styles.section}>
          <h2 className={styles.sectionTitle}>Your Order</h2>
          <ul className={styles.orderList}>
            {items.map((item) => (
              <li key={item.menuItemId} className={styles.orderItem}>
                <div className={styles.thumb}>
                  {item.imageUrl ? (
                    <img src={item.imageUrl} alt={item.name} />
                  ) : (
                    <UtensilsCrossed size={18} />
                  )}
                </div>
                <div className={styles.orderInfo}>
                  <span className={styles.orderName}>{item.name}</span>
                  <span className={styles.orderPrice}>₹{item.price}</span>
                </div>
                <span className={styles.orderQty}>× {item.quantity}</span>
              </li>
            ))}
          </ul>
        </section>

        <section className={styles.section}>
          <h2 className={styles.sectionTitle}>Bill Details</h2>
          <dl className={styles.bill}>
            <div className={styles.billRow}>
              <dt>Subtotal</dt>
              <dd>₹{subtotal}</dd>
            </div>
            <div className={styles.billRow}>
              <dt>Packaging Charge</dt>
              <dd>₹{PACKAGING_CHARGE}</dd>
            </div>
            <div className={`${styles.billRow} ${styles.billTotal}`}>
              <dt>Total</dt>
              <dd>₹{total}</dd>
            </div>
          </dl>
        </section>

        <section className={styles.section}>
          <h2 className={styles.sectionTitle}>Select Payment Method</h2>
          {loadingConfig ? (
            <div className={styles.processing}>
              <Loader2 size={24} className={styles.spinner} />
            </div>
          ) : (
            <div className={styles.paymentOptions}>
              {razorpayEnabled ? (
                <label
                  className={`${styles.paymentCard} ${selectedMethod === 'RAZORPAY' ? styles.paymentCardActive : ''}`}
                >
                  <input
                    type="radio"
                    name="payment"
                    checked={selectedMethod === 'RAZORPAY'}
                    onChange={() => setSelectedMethod('RAZORPAY')}
                    className={styles.radioInput}
                    disabled={isProcessing}
                  />
                  <span className={styles.paymentIcon}>
                    <CreditCard size={22} />
                  </span>
                  <span className={styles.paymentText}>
                    <span className={styles.paymentLabel}>Pay Online</span>
                    <span className={styles.paymentDesc}>
                      {testMode
                        ? 'Razorpay test mode — no real money'
                        : 'UPI · Cards · Net Banking'}
                    </span>
                  </span>
                </label>
              ) : (
                <p className={styles.paymentDesc}>
                  Online payment is not configured on the server yet. Use Pay at
                  Counter, or add Razorpay test keys to the backend.
                </p>
              )}

              <label
                className={`${styles.paymentCard} ${selectedMethod === 'PAY_AT_COUNTER' ? styles.paymentCardActive : ''}`}
              >
                <input
                  type="radio"
                  name="payment"
                  checked={selectedMethod === 'PAY_AT_COUNTER'}
                  onChange={() => setSelectedMethod('PAY_AT_COUNTER')}
                  className={styles.radioInput}
                  disabled={isProcessing}
                />
                <span className={styles.paymentIcon}>
                  <Store size={22} />
                </span>
                <span className={styles.paymentText}>
                  <span className={styles.paymentLabel}>Pay at Counter</span>
                  <span className={styles.paymentDesc}>
                    Pay when you collect your order
                  </span>
                </span>
              </label>
            </div>
          )}
        </section>

        {error && <p className={styles.error}>{error}</p>}

        {isProcessing && (
          <motion.div
            className={styles.processing}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
          >
            <Loader2 size={28} className={styles.spinner} />
            <p>Processing payment…</p>
          </motion.div>
        )}

        <p className={styles.secure}>
          <ShieldCheck size={16} />
          Your order is safe and secure
        </p>

        <button
          type="button"
          className={styles.placeBtn}
          onClick={handleConfirm}
          disabled={isProcessing || loadingConfig}
        >
          {isProcessing ? 'Please wait…' : 'PLACE ORDER'}
        </button>
      </div>
    </div>
  );
};

export default StudentCheckoutPage;
