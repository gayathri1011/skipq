import { useEffect, useState, type FormEvent } from 'react';
import {
  Apple,
  Banana,
  Bean,
  Beef,
  CakeSlice,
  Candy,
  Carrot,
  Check,
  ChefHat,
  Cherry,
  ChevronRight,
  CircleDot,
  CirclePlus,
  Citrus,
  Cookie,
  CookingPot,
  CupSoda,
  Croissant,
  Donut,
  Drumstick,
  Egg,
  Fish,
  Flame,
  GlassWater,
  Glasses,
  Grape,
  Ham,
  IceCreamBowl,
  Leaf,
  Martini,
  Milk,
  Nut,
  PackageOpen,
  Pencil,
  Pizza,
  Popcorn,
  Salad,
  Sandwich,
  Soup,
  Trash2,
  UtensilsCrossed,
  Wheat,
  Wine,
  X,
  type LucideIcon,
} from 'lucide-react';
import {
  fetchManagerMenu,
  createMenuItem,
  updateMenuItem,
  updateMenuItemPrice,
  toggleMenuItemAvailability,
  deleteMenuItem,
  createCategory,
  updateCategory,
  deleteCategory,
} from '../services/managerMenu';
import type { Category, MenuItem } from '../types/menu';
import { FoodCardSkeletonGrid } from '../components/FoodCardSkeleton';
import { EmptyState } from '../components/ui/UiStates';
import styles from './ManagerMenuPage.module.css';

const normalizeId = (id: unknown) => String(id ?? '');

const categoryIcons = [
  { key: 'restaurant', label: 'Restaurant', icon: UtensilsCrossed },
  { key: 'rice_bowl', label: 'Rice bowl', icon: Soup },
  { key: 'fastfood', label: 'Fast food', icon: ChefHat },
  { key: 'local_pizza', label: 'Pizza', icon: Pizza },
  { key: 'cake', label: 'Cake', icon: CakeSlice },
  { key: 'icecream', label: 'Ice cream', icon: IceCreamBowl },
  { key: 'bakery_dining', label: 'Bakery', icon: Croissant },
  { key: 'apple', label: 'Apple', icon: Apple },
  { key: 'banana', label: 'Banana', icon: Banana },
  { key: 'beef', label: 'Beef', icon: Beef },
  { key: 'candy', label: 'Candy', icon: Candy },
  { key: 'carrot', label: 'Carrot', icon: Carrot },
  { key: 'cherry', label: 'Cherry', icon: Cherry },
  { key: 'citrus', label: 'Citrus', icon: Citrus },
  { key: 'cookie', label: 'Cookie', icon: Cookie },
  { key: 'cooking_pot', label: 'Cooking pot', icon: CookingPot },
  { key: 'cup_soda', label: 'Soft drink', icon: CupSoda },
  { key: 'donut', label: 'Donut', icon: Donut },
  { key: 'drumstick', label: 'Drumstick', icon: Drumstick },
  { key: 'egg', label: 'Egg', icon: Egg },
  { key: 'fish', label: 'Fish', icon: Fish },
  { key: 'flame', label: 'Spicy', icon: Flame },
  { key: 'glass_water', label: 'Water', icon: GlassWater },
  { key: 'glasses', label: 'Glasses', icon: Glasses },
  { key: 'grape', label: 'Grape', icon: Grape },
  { key: 'ham', label: 'Ham', icon: Ham },
  { key: 'leaf', label: 'Leaf', icon: Leaf },
  { key: 'martini', label: 'Drink', icon: Martini },
  { key: 'milk', label: 'Milk', icon: Milk },
  { key: 'nut', label: 'Nut', icon: Nut },
  { key: 'package_open', label: 'Takeaway', icon: PackageOpen },
  { key: 'popcorn', label: 'Popcorn', icon: Popcorn },
  { key: 'salad', label: 'Salad', icon: Salad },
  { key: 'sandwich', label: 'Sandwich', icon: Sandwich },
  { key: 'wheat', label: 'Wheat', icon: Wheat },
  { key: 'wine', label: 'Beverage', icon: Wine },
  { key: 'indian_thali', label: 'Indian thali', icon: UtensilsCrossed },
  { key: 'tandoor', label: 'Tandoor', icon: CookingPot },
  { key: 'curry_pot', label: 'Curry pot', icon: CookingPot },
  { key: 'spice', label: 'Spices', icon: Flame },
  { key: 'lentils', label: 'Lentils', icon: Bean },
  { key: 'coriander', label: 'Coriander', icon: Leaf },
  { key: 'masala', label: 'Masala', icon: Soup },
  { key: 'roti', label: 'Roti', icon: Wheat },
  { key: 'idli', label: 'Idli', icon: CircleDot },
  { key: 'chai', label: 'Chai', icon: CupSoda },
] satisfies { key: string; label: string; icon: LucideIcon }[];

const getCategoryIcon = (key?: string) =>
  categoryIcons.find((item) => item.key === key)?.icon ?? UtensilsCrossed;

const resolveCategoryId = (item: MenuItem, categories: Category[]) => {
  const itemCat = normalizeId(item.categoryId);
  if (categories.some((c) => normalizeId(c._id) === itemCat)) return itemCat;
  return categories[0] ? normalizeId(categories[0]._id) : '';
};

const ManagerMenuPage = () => {
  const [categories, setCategories] = useState<Category[]>([]);
  const [items, setItems] = useState<MenuItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [editingId, setEditingId] = useState<string | null>(null);
  const [priceEdits, setPriceEdits] = useState<Record<string, string>>({});
  const [savingPriceId, setSavingPriceId] = useState<string | null>(null);

  const [form, setForm] = useState({
    name: '',
    description: '',
    price: '',
    isVeg: true,
  });
  const [formImage, setFormImage] = useState<File | null>(null);
  const [formLoading, setFormLoading] = useState(false);

  const [editForm, setEditForm] = useState({
    name: '',
    description: '',
    price: '',
    categoryId: '',
    isVeg: true,
  });
  const [editImage, setEditImage] = useState<File | null>(null);
  const [categoryForm, setCategoryForm] = useState({
    name: '',
    icon: 'restaurant',
    sortOrder: '0',
  });
  const [editingCategoryId, setEditingCategoryId] = useState<string | null>(
    null,
  );
  const [selectedCategoryId, setSelectedCategoryId] = useState<string | null>(
    null,
  );
  const [showCategoryModal, setShowCategoryModal] = useState(false);

  const selectCategory = (categoryId: string | null) => {
    setSelectedCategoryId(categoryId);
  };

  useEffect(() => {
    let cancelled = false;

    fetchManagerMenu()
      .then((data) => {
        if (!cancelled) {
          setCategories(data.categories);
          setItems(data.items);
        }
      })
      .catch(() => {
        if (!cancelled) setError('Unable to load menu.');
      })
      .finally(() => {
        if (!cancelled) setIsLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, []);

  const handleCreate = async (e: FormEvent) => {
    e.preventDefault();
    if (!selectedCategoryId) {
      setError('Select a category above to add an item to it.');
      return;
    }

    setFormLoading(true);
    setError('');
    try {
      const fd = new FormData();
      fd.append('name', form.name);
      fd.append('description', form.description);
      fd.append('price', form.price);
      fd.append('categoryId', selectedCategoryId);
      fd.append('isVeg', String(form.isVeg));
      if (formImage) fd.append('image', formImage);

      const item = await createMenuItem(fd);
      setItems((prev) =>
        [...prev, item].sort((a, b) => a.name.localeCompare(b.name)),
      );
      setForm({
        name: '',
        description: '',
        price: '',
        isVeg: true,
      });
      setFormImage(null);
    } catch {
      setError('Unable to create item.');
    } finally {
      setFormLoading(false);
    }
  };

  const startEdit = (item: MenuItem) => {
    setEditingId(item.id);
    setEditForm({
      name: item.name,
      description: item.description,
      price: String(item.price),
      categoryId: resolveCategoryId(item, categories),
      isVeg: item.isVeg,
    });
    setEditImage(null);
  };

  const handleFinishEdit = async (id: string) => {
    setFormLoading(true);
    try {
      const fd = new FormData();
      fd.append('name', editForm.name);
      fd.append('description', editForm.description);
      fd.append('price', editForm.price);
      fd.append('categoryId', editForm.categoryId);
      fd.append('isVeg', String(editForm.isVeg));
      if (editImage) fd.append('image', editImage);

      const updated = await updateMenuItem(id, fd);
      setItems((prev) => prev.map((i) => (i.id === id ? updated : i)));
      setEditingId(null);
    } catch {
      setError('Unable to update item.');
    } finally {
      setFormLoading(false);
    }
  };

  const handlePriceBlur = async (item: MenuItem) => {
    const raw = priceEdits[item.id];
    if (raw === undefined) return;

    const price = Number(raw);
    if (Number.isNaN(price) || price < 0) {
      setPriceEdits((prev) => {
        const next = { ...prev };
        delete next[item.id];
        return next;
      });
      return;
    }

    if (price === item.price) {
      setPriceEdits((prev) => {
        const next = { ...prev };
        delete next[item.id];
        return next;
      });
      return;
    }

    setSavingPriceId(item.id);
    try {
      const updated = await updateMenuItemPrice(item.id, price);
      setItems((prev) => prev.map((i) => (i.id === item.id ? updated : i)));
      setPriceEdits((prev) => {
        const next = { ...prev };
        delete next[item.id];
        return next;
      });
    } catch {
      setError('Unable to update price.');
    } finally {
      setSavingPriceId(null);
    }
  };

  const handleToggle = async (id: string) => {
    try {
      const updated = await toggleMenuItemAvailability(id);
      setItems((prev) => prev.map((i) => (i.id === id ? updated : i)));
    } catch {
      setError('Unable to toggle availability.');
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('Delete this menu item?')) return;
    try {
      await deleteMenuItem(id);
      setItems((prev) => prev.filter((i) => i.id !== id));
    } catch {
      setError('Unable to delete item.');
    }
  };

  const saveCategory = async (e: FormEvent) => {
    e.preventDefault();
    setFormLoading(true);
    setError('');
    try {
      const payload = {
        name: categoryForm.name.trim(),
        icon: categoryForm.icon,
        sortOrder: Number(categoryForm.sortOrder) || 0,
      };
      const category = editingCategoryId
        ? await updateCategory(editingCategoryId, payload)
        : await createCategory(payload);
      setCategories((prev) => {
        const next = editingCategoryId
          ? prev.map((item) => (item._id === category._id ? category : item))
          : [...prev, category];
        return [...next].sort(
          (a, b) =>
            (a.sortOrder ?? 0) - (b.sortOrder ?? 0) ||
            a.name.localeCompare(b.name),
        );
      });
      setForm((current) => ({
        ...current,
        categoryId: editingCategoryId ?? normalizeId(category._id),
      }));
      setCategoryForm({ name: '', icon: 'restaurant', sortOrder: '0' });
      setEditingCategoryId(null);
      return true;
    } catch {
      setError('Unable to save category.');
      return false;
    } finally {
      setFormLoading(false);
    }
  };

  const startCategoryEdit = (category: Category) => {
    setEditingCategoryId(category._id);
    setCategoryForm({
      name: category.name,
      icon: category.icon ?? 'restaurant',
      sortOrder: String(category.sortOrder ?? 0),
    });
  };

  const handleDeleteCategory = async (id: string) => {
    if (!window.confirm('Delete this category?')) return;

    try {
      await deleteCategory(id);
      const remaining = categories.filter((category) => category._id !== id);
      setCategories(remaining);
      if (selectedCategoryId === id) {
        selectCategory(remaining[0] ? normalizeId(remaining[0]._id) : null);
      }
      setError('Category deleted.');
    } catch {
      setError(
        'This category still has menu items in it. Move or delete those items first.',
      );
    }
  };

  const filteredItems = selectedCategoryId
    ? items.filter((item) => normalizeId(item.categoryId) === selectedCategoryId)
    : items;

  const renderCategoryOptions = (placeholder: string) => {
    if (categories.length === 0) {
      return (
        <option value="" disabled>
          No categories — run seed script
        </option>
      );
    }

    return (
      <>
        <option value="" disabled>
          {placeholder}
        </option>
        {categories.map((c) => (
          <option key={c._id} value={normalizeId(c._id)}>
            {c.name}
          </option>
        ))}
      </>
    );
  };

  return (
    <div className={styles.page}>
      <section className={styles.section}>
        <div className={styles.categoryHeader}>
          <div>
            <h2 className={styles.sectionTitle}>Category Master</h2>
            <p className={styles.sectionHint}>
              Select a category to manage its menu items.
            </p>
          </div>
          {selectedCategoryId && (
            <button
              type="button"
              className={styles.clearCategoryBtn}
              onClick={() => selectCategory(null)}
            >
              All items
            </button>
          )}
        </div>
        <ul className={styles.categorySlider}>
          {categories.map((category) => (
            <li
              key={category._id}
              className={`${styles.categoryCard} ${selectedCategoryId === category._id ? styles.categoryCardActive : ''}`}
            >
              <button
                type="button"
                className={styles.categorySelectBtn}
                onClick={() =>
                  selectCategory(
                    selectedCategoryId === category._id
                      ? null
                      : category._id,
                  )
                }
              >
                {(() => {
                  const Icon = getCategoryIcon(category.icon);
                  return <Icon size={25} />;
                })()}
                <span>{category.name}</span>
                <ChevronRight size={15} className={styles.categoryArrow} />
              </button>
              <span className={styles.categoryActions}>
                <button
                  type="button"
                  className={styles.iconBtn}
                  aria-label={`Edit ${category.name}`}
                  onClick={() => {
                    startCategoryEdit(category);
                    setShowCategoryModal(true);
                  }}
                >
                  <Pencil size={16} />
                </button>
                <button
                  type="button"
                  className={styles.iconBtn}
                  aria-label={`Delete ${category.name}`}
                  onClick={() => handleDeleteCategory(category._id)}
                >
                  <Trash2 size={16} />
                </button>
              </span>
            </li>
          ))}
          <li className={styles.newCategoryCard}>
            <button
              type="button"
              className={styles.newCategoryBtn}
              onClick={() => {
                setEditingCategoryId(null);
                setCategoryForm({
                  name: '',
                  icon: 'restaurant',
                  sortOrder: String(categories.length),
                });
                setShowCategoryModal(true);
              }}
            >
              <CirclePlus size={25} />
              <span>+ New Category</span>
            </button>
          </li>
        </ul>

        {showCategoryModal && (
          <div className={styles.modalBackdrop} role="presentation">
            <form
              className={styles.modal}
              onSubmit={(event) => {
                void saveCategory(event).then((saved) => {
                  if (saved) setShowCategoryModal(false);
                });
              }}
            >
              <div className={styles.modalHeader}>
                <h3>{editingCategoryId ? 'Edit Category' : 'New Category'}</h3>
                <button
                  type="button"
                  className={styles.iconBtn}
                  aria-label="Close category dialog"
                  onClick={() => setShowCategoryModal(false)}
                >
                  <X size={18} />
                </button>
              </div>
              <label className={styles.field}>
                <span className={styles.fieldLabel}>Category name</span>
                <input
                  className={styles.input}
                  value={categoryForm.name}
                  required
                  autoFocus
                  onChange={(e) =>
                    setCategoryForm({ ...categoryForm, name: e.target.value })
                  }
                />
              </label>
              <div className={styles.field}>
                <span className={styles.fieldLabel}>Choose icon</span>
                <div className={styles.iconGrid}>
                  {categoryIcons.map(({ key, label, icon: Icon }) => (
                    <button
                      key={key}
                      type="button"
                      className={`${styles.iconChoice} ${categoryForm.icon === key ? styles.iconChoiceActive : ''}`}
                      onClick={() => setCategoryForm({ ...categoryForm, icon: key })}
                    >
                      <Icon size={20} />
                      <span>{label}</span>
                    </button>
                  ))}
                </div>
              </div>
              <label className={styles.field}>
                <span className={styles.fieldLabel}>Display order</span>
                <input
                  className={styles.input}
                  type="number"
                  min="0"
                  value={categoryForm.sortOrder}
                  onChange={(e) =>
                    setCategoryForm({ ...categoryForm, sortOrder: e.target.value })
                  }
                />
              </label>
              <div className={styles.modalActions}>
                <button
                  type="button"
                  className={styles.cancelBtn}
                  onClick={() => setShowCategoryModal(false)}
                >
                  Cancel
                </button>
                <button className={styles.addBtn} type="submit" disabled={formLoading}>
                  Save
                </button>
              </div>
            </form>
          </div>
        )}
      </section>
      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>Add New Item</h2>
        <p className={styles.sectionHint}>
          {selectedCategoryId
            ? `Fill in the details below to add a dish to ${categories.find((category) => category._id === selectedCategoryId)?.name ?? 'the selected category'}.`
            : 'Select a category above to add an item to it.'}
        </p>
        {selectedCategoryId && (
          <p className={styles.addingTo}>
            Adding to:{' '}
            <strong>
              {categories.find((category) => category._id === selectedCategoryId)?.name}
            </strong>
          </p>
        )}
        <fieldset
          className={styles.formFieldset}
          disabled={!selectedCategoryId || formLoading}
        >
          <form className={styles.addForm} onSubmit={handleCreate}>
          <label className={styles.field}>
            <span className={styles.fieldLabel}>Item name</span>
            <input
              type="text"
              placeholder="e.g. Veg Fried Rice"
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              required
              className={styles.input}
            />
          </label>
          <label className={styles.field}>
            <span className={styles.fieldLabel}>Description</span>
            <input
              type="text"
              placeholder="Optional short description"
              value={form.description}
              onChange={(e) =>
                setForm({ ...form, description: e.target.value })
              }
              className={styles.input}
            />
          </label>
          <label className={styles.field}>
            <span className={styles.fieldLabel}>Price (₹)</span>
            <input
              type="number"
              placeholder="0"
              value={form.price}
              onChange={(e) => setForm({ ...form, price: e.target.value })}
              required
              min={0}
              className={styles.input}
            />
          </label>
          <label className={styles.checkLabel}>
            <input
              type="checkbox"
              checked={form.isVeg}
              onChange={(e) => setForm({ ...form, isVeg: e.target.checked })}
            />
            Vegetarian
          </label>
          <label className={styles.field}>
            <span className={styles.fieldLabel}>Photo</span>
            <input
              type="file"
              accept="image/*"
              onChange={(e) => setFormImage(e.target.files?.[0] ?? null)}
              className={styles.fileInput}
            />
          </label>
          <button
            type="submit"
            className={styles.addBtn}
            disabled={!selectedCategoryId || formLoading}
          >
            Add Item
          </button>
          </form>
        </fieldset>
      </section>

      {error && <p className={styles.error}>{error}</p>}

      {isLoading && (
        <div className={styles.list}>
          <FoodCardSkeletonGrid count={4} />
        </div>
      )}

      {!isLoading && !error && items.length === 0 && (
        <EmptyState
          icon={UtensilsCrossed}
          title="No menu items"
          message="Add your first dish using the form above."
        />
      )}

      {!isLoading && items.length > 0 && (
        <section className={styles.section}>
          <h2 className={styles.sectionTitle}>Menu Items</h2>
          <p className={styles.sectionHint}>
            Edit price inline — changes apply when you leave the field. Use the
            pencil to edit other details.
          </p>
          <ul className={styles.list}>
            {filteredItems.map((item) => (
              <li key={item.id} className={styles.itemRow}>
                <div className={styles.imageWrap}>
                  {item.imageUrl ? (
                    <img
                      src={item.imageUrl}
                      alt={item.name}
                      className={styles.image}
                    />
                  ) : (
                    <div className={styles.placeholder}>
                      <UtensilsCrossed size={28} />
                    </div>
                  )}
                  {!item.available && (
                    <span className={styles.soldOutBadge}>Sold Out</span>
                  )}
                </div>

                {editingId === item.id ? (
                  <div className={styles.editPanel}>
                    <div className={styles.editGrid}>
                      <label className={styles.field}>
                        <span className={styles.fieldLabel}>Name</span>
                        <input
                          value={editForm.name}
                          onChange={(e) =>
                            setEditForm({ ...editForm, name: e.target.value })
                          }
                          className={styles.input}
                        />
                      </label>
                      <label className={styles.field}>
                        <span className={styles.fieldLabel}>Description</span>
                        <input
                          value={editForm.description}
                          onChange={(e) =>
                            setEditForm({
                              ...editForm,
                              description: e.target.value,
                            })
                          }
                          className={styles.input}
                        />
                      </label>
                      <label className={styles.field}>
                        <span className={styles.fieldLabel}>Price (₹)</span>
                        <input
                          type="number"
                          min={0}
                          value={editForm.price}
                          onChange={(e) =>
                            setEditForm({ ...editForm, price: e.target.value })
                          }
                          className={styles.input}
                        />
                      </label>
                      <label className={styles.field}>
                        <span className={styles.fieldLabel}>Category</span>
                        <select
                          value={editForm.categoryId}
                          onChange={(e) =>
                            setEditForm({
                              ...editForm,
                              categoryId: e.target.value,
                            })
                          }
                          className={styles.select}
                        >
                          {renderCategoryOptions('Choose category')}
                        </select>
                      </label>
                      <label className={styles.checkLabel}>
                        <input
                          type="checkbox"
                          checked={editForm.isVeg}
                          onChange={(e) =>
                            setEditForm({
                              ...editForm,
                              isVeg: e.target.checked,
                            })
                          }
                        />
                        Vegetarian
                      </label>
                      <label className={styles.field}>
                        <span className={styles.fieldLabel}>New photo</span>
                        <input
                          type="file"
                          accept="image/*"
                          onChange={(e) =>
                            setEditImage(e.target.files?.[0] ?? null)
                          }
                          className={styles.fileInput}
                        />
                      </label>
                    </div>
                    <div className={styles.editActions}>
                      <button
                        type="button"
                        className={styles.doneBtn}
                        onClick={() => handleFinishEdit(item.id)}
                        disabled={formLoading}
                        title="Done editing"
                      >
                        <Check size={18} />
                        Done
                      </button>
                      <button
                        type="button"
                        className={styles.cancelBtn}
                        onClick={() => setEditingId(null)}
                        title="Cancel editing"
                      >
                        <X size={18} />
                        Cancel
                      </button>
                    </div>
                  </div>
                ) : (
                  <div className={styles.itemBody}>
                    <div className={styles.itemHeader}>
                      <div>
                        <h3 className={styles.itemName}>{item.name}</h3>
                        <p className={styles.category}>{item.categoryName}</p>
                      </div>
                      {item.isVeg && (
                        <span className={`${styles.vegBadge} ${styles.vegBadgeVeg}`}>
                          Veg
                        </span>
                      )}
                    </div>

                    {item.description && (
                      <p className={styles.description}>{item.description}</p>
                    )}

                    <div className={styles.itemFooter}>
                      <label className={styles.priceField}>
                        <span className={styles.fieldLabel}>Price (₹)</span>
                        <input
                          type="number"
                          value={priceEdits[item.id] ?? item.price}
                          onChange={(e) =>
                            setPriceEdits({
                              ...priceEdits,
                              [item.id]: e.target.value,
                            })
                          }
                          onBlur={() => handlePriceBlur(item)}
                          onKeyDown={(e) => {
                            if (e.key === 'Enter') {
                              e.currentTarget.blur();
                            }
                          }}
                          className={styles.priceInput}
                          min={0}
                          disabled={savingPriceId === item.id}
                        />
                      </label>

                      <div className={styles.cardActions}>
                        <button
                          type="button"
                          className={styles.iconBtn}
                          onClick={() => startEdit(item)}
                          title="Edit item"
                        >
                          <Pencil size={18} />
                        </button>
                        <button
                          type="button"
                          className={`${styles.availBtn} ${item.available ? styles.availOn : styles.availOff}`}
                          onClick={() => handleToggle(item.id)}
                        >
                          {item.available ? 'Available' : 'Unavailable'}
                        </button>
                        <button
                          type="button"
                          className={styles.iconBtnDanger}
                          onClick={() => handleDelete(item.id)}
                          title="Delete item"
                        >
                          <Trash2 size={18} />
                        </button>
                      </div>
                    </div>
                  </div>
                )}
              </li>
            ))}
          </ul>
        </section>
      )}
    </div>
  );
};

export default ManagerMenuPage;
