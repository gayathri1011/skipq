import { useEffect, useMemo, useState } from 'react';
import { Search, SlidersHorizontal, UtensilsCrossed } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useOrderingWindow } from '../context/OrderingWindowContext';
import { fetchCategories, fetchMenuItems } from '../services/menu';
import type { Category, MenuItem, VegFilter } from '../types/menu';
import FoodCard from '../components/FoodCard';
import { FoodCardSkeletonGrid } from '../components/FoodCardSkeleton';
import { EmptyState } from '../components/ui/UiStates';
import { getCategoryIconByKey, getTimeGreeting } from '../utils/greeting';
import styles from './StudentHomePage.module.css';

const StudentHomePage = () => {
  const { user } = useAuth();
  const { isOpen: orderingOpen } = useOrderingWindow();
  const [categories, setCategories] = useState<Category[]>([]);
  const [menuItems, setMenuItems] = useState<MenuItem[]>([]);
  const [selectedCategoryId, setSelectedCategoryId] = useState<string | null>(
    null,
  );
  const [searchQuery, setSearchQuery] = useState('');
  const [vegFilter, setVegFilter] = useState<VegFilter>('all');
  const [showFilters, setShowFilters] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    let cancelled = false;

    const loadMenu = async () => {
      try {
        const [cats, items] = await Promise.all([
          fetchCategories(),
          fetchMenuItems(),
        ]);
        if (cancelled) return;
        setCategories(cats);
        setMenuItems(items);
        setError('');
      } catch {
        if (!cancelled) setError('Unable to load menu. Please try again.');
      } finally {
        if (!cancelled) setIsLoading(false);
      }
    };

    const refreshWhenVisible = () => {
      if (document.visibilityState === 'visible') void loadMenu();
    };

    void loadMenu();
    window.addEventListener('focus', refreshWhenVisible);
    document.addEventListener('visibilitychange', refreshWhenVisible);

    return () => {
      cancelled = true;
      window.removeEventListener('focus', refreshWhenVisible);
      document.removeEventListener('visibilitychange', refreshWhenVisible);
    };
  }, []);

  const filteredItems = useMemo(() => {
    let result = menuItems;

    if (selectedCategoryId) {
      result = result.filter((item) => item.categoryId === selectedCategoryId);
    }

    if (vegFilter === 'veg') {
      result = result.filter((item) => item.isVeg);
    }

    const query = searchQuery.trim().toLowerCase();
    if (query) {
      result = result.filter(
        (item) =>
          item.name.toLowerCase().includes(query) ||
          item.description.toLowerCase().includes(query) ||
          item.categoryName.toLowerCase().includes(query),
      );
    }

    return result;
  }, [menuItems, selectedCategoryId, vegFilter, searchQuery]);

  if (user?.role !== 'student') return null;

  const firstName = user.name.split(' ')[0];
  const emptyMessage = searchQuery.trim()
    ? {
        title: 'No matches found',
        message: 'Try a different search term or clear filters.',
      }
    : selectedCategoryId
      ? {
          title: 'Nothing here yet',
          message: 'No menu items in this category right now.',
        }
      : {
          title: 'Menu unavailable',
          message: 'Check back soon — the canteen menu is being updated.',
        };

  return (
    <div className={styles.page}>
      <h1 className={styles.greeting}>
        {getTimeGreeting()}, {firstName} 👋
      </h1>
      <p className={styles.subtext}>What would you like to order today?</p>

      {!orderingOpen && (
        <div className={styles.closedBanner}>
          Ordering is closed. Please visit the canteen directly.
        </div>
      )}

      <div className={styles.searchRow}>
        <div className={styles.searchWrap}>
          <Search size={18} className={styles.searchIcon} />
          <input
            type="search"
            className={styles.searchInput}
            placeholder="Search food..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
        <button
          type="button"
          className={styles.filterBtn}
          onClick={() => setShowFilters((v) => !v)}
          aria-label="Toggle filters"
        >
          <SlidersHorizontal size={18} />
        </button>
      </div>

      {showFilters && (
        <div className={styles.filterPanel}>
          {(['all', 'veg'] as VegFilter[]).map((f) => (
            <button
              key={f}
              type="button"
              className={`${styles.filterChip} ${vegFilter === f ? styles.filterChipActive : ''}`}
              onClick={() => setVegFilter(f)}
            >
              {f === 'all' ? 'All' : 'Veg'}
            </button>
          ))}
        </div>
      )}

      <div className={styles.categoryScroll}>
        <button
          type="button"
          className={`${styles.categoryItem} ${selectedCategoryId === null ? styles.categoryItemActive : ''}`}
          onClick={() => setSelectedCategoryId(null)}
        >
          <span className={styles.categoryIcon}>
            <UtensilsCrossed size={22} />
          </span>
          <span className={styles.categoryLabel}>All</span>
        </button>
        {categories.map((cat) => {
          const Icon = getCategoryIconByKey(cat.icon);
          return (
            <button
              key={cat._id}
              type="button"
              className={`${styles.categoryItem} ${selectedCategoryId === cat._id ? styles.categoryItemActive : ''}`}
              onClick={() => setSelectedCategoryId(cat._id)}
            >
              <span className={styles.categoryIcon}>
                <Icon size={22} />
              </span>
              <span className={styles.categoryLabel}>{cat.name}</span>
            </button>
          );
        })}
      </div>

      <h2 className={styles.sectionTitle}>Today&apos;s Menu</h2>

      {error && <p className={styles.error}>{error}</p>}

      {isLoading && (
        <div className={styles.list}>
          <FoodCardSkeletonGrid count={6} />
        </div>
      )}

      {!isLoading && !error && filteredItems.length === 0 && (
        <EmptyState
          icon={UtensilsCrossed}
          title={emptyMessage.title}
          message={emptyMessage.message}
        />
      )}

      {!isLoading && !error && filteredItems.length > 0 && (
        <div className={styles.list}>
          {filteredItems.map((item) => (
            <FoodCard key={item.id} item={item} orderingOpen={orderingOpen} />
          ))}
        </div>
      )}
    </div>
  );
};

export default StudentHomePage;
