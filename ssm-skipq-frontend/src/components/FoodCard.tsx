import { motion, AnimatePresence } from 'framer-motion';
import { UtensilsCrossed, Minus, Plus } from 'lucide-react';
import type { MenuItem } from '../types/menu';
import { useCart } from '../context/CartContext';
import styles from './FoodCard.module.css';

interface FoodCardProps {
  item: MenuItem;
  orderingOpen?: boolean;
}

const FoodCard = ({ item, orderingOpen = true }: FoodCardProps) => {
  const { getQuantity, addItem, increment, decrement } = useCart();
  const quantity = getQuantity(item.id);

  const handleAdd = () => {
    addItem({
      menuItemId: item.id,
      name: item.name,
      price: item.price,
      imageUrl: item.imageUrl,
      isVeg: item.isVeg,
      available: item.available,
    });
  };

  return (
    <article className={styles.card}>
      <div className={styles.imageWrap}>
        {item.imageUrl ? (
          <img src={item.imageUrl} alt={item.name} className={styles.image} />
        ) : (
          <div className={styles.placeholder}>
            <UtensilsCrossed size={28} strokeWidth={1.5} />
          </div>
        )}
        {item.isVeg && <span className={`${styles.vegDot} ${styles.vegDotVeg}`} title="Vegetarian" />}
      </div>

      <div className={styles.body}>
        <h3 className={styles.name}>{item.name}</h3>
        {item.description && (
          <p className={styles.description}>{item.description}</p>
        )}
        <div className={styles.footer}>
          <span className={styles.price}>₹{item.price}</span>

          {!item.available ? (
            <span className={styles.soldOut}>Sold Out</span>
          ) : !orderingOpen ? (
            <span
              className={styles.closed}
              title="Ordering is closed. Please visit the canteen directly."
            >
              Closed
            </span>
          ) : (
            <AnimatePresence mode="wait" initial={false}>
              {quantity === 0 ? (
                <motion.button
                  key="add"
                  type="button"
                  className={styles.addBtn}
                  onClick={handleAdd}
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.8 }}
                  transition={{ type: 'spring', stiffness: 400, damping: 25 }}
                  layout
                >
                  ADD
                </motion.button>
              ) : (
                <motion.div
                  key="stepper"
                  className={styles.stepper}
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.8 }}
                  transition={{ type: 'spring', stiffness: 400, damping: 25 }}
                  layout
                >
                  <button
                    type="button"
                    className={styles.stepperBtn}
                    onClick={() => decrement(item.id)}
                    aria-label="Decrease quantity"
                  >
                    <Minus size={14} />
                  </button>
                  <span className={styles.qty}>{quantity}</span>
                  <button
                    type="button"
                    className={styles.stepperBtn}
                    onClick={() => increment(item.id)}
                    aria-label="Increase quantity"
                  >
                    <Plus size={14} />
                  </button>
                </motion.div>
              )}
            </AnimatePresence>
          )}
        </div>
      </div>
    </article>
  );
};

export default FoodCard;
