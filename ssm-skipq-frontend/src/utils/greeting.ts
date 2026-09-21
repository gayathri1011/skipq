import type { LucideIcon } from 'lucide-react';
import {
  Apple,
  Banana,
  Bean,
  Cake,
  Candy,
  Carrot,
  ChefHat,
  Cherry,
  Coffee,
  Cookie,
  CookingPot,
  CupSoda,
  Croissant,
  Citrus,
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
  Pizza,
  Popcorn,
  Salad,
  Sandwich,
  Soup,
  UtensilsCrossed,
  Wheat,
  Wine,
} from 'lucide-react';

const CATEGORY_ICONS: Record<string, LucideIcon> = {
  'Rice Varieties': Wheat,
  Parotta: Pizza,
  'Fried Rice': Soup,
  Chapati: Leaf,
  'Side Dishes': Drumstick,
  Gravies: Coffee,
  Puffs: Cookie,
  Snacks: UtensilsCrossed,
  Desserts: Cake,
};

export const getCategoryIcon = (name: string): LucideIcon =>
  CATEGORY_ICONS[name] ?? UtensilsCrossed;

const CATEGORY_ICONS_BY_KEY: Record<string, LucideIcon> = {
  restaurant: UtensilsCrossed,
  rice_bowl: Wheat,
  fastfood: ChefHat,
  local_pizza: Pizza,
  cake: Cake,
  icecream: IceCreamBowl,
  bakery_dining: Croissant,
  apple: Apple,
  banana: Banana,
  beef: Drumstick,
  candy: Candy,
  carrot: Carrot,
  cherry: Cherry,
  citrus: Citrus,
  cookie: Cookie,
  cooking_pot: CookingPot,
  cup_soda: CupSoda,
  donut: Donut,
  drumstick: Drumstick,
  egg: Egg,
  fish: Fish,
  flame: Flame,
  glass_water: GlassWater,
  glasses: Glasses,
  grape: Grape,
  ham: Ham,
  leaf: Leaf,
  martini: Martini,
  milk: Milk,
  nut: Nut,
  package_open: PackageOpen,
  popcorn: Popcorn,
  salad: Salad,
  sandwich: Sandwich,
  wheat: Wheat,
  wine: Wine,
  indian_thali: UtensilsCrossed,
  tandoor: CookingPot,
  curry_pot: CookingPot,
  spice: Flame,
  lentils: Bean,
  coriander: Leaf,
  masala: Soup,
  roti: Wheat,
  idli: Soup,
  chai: CupSoda,
};

export const getCategoryIconByKey = (key?: string | null): LucideIcon =>
  CATEGORY_ICONS_BY_KEY[key ?? ''] ?? UtensilsCrossed;

export const getTimeGreeting = () => {
  const hour = Number(
    new Intl.DateTimeFormat('en-IN', {
      hour: 'numeric',
      hour12: false,
      timeZone: 'Asia/Kolkata',
    }).format(new Date()),
  );

  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
};
