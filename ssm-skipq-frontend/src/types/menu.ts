export interface Category {
  _id: string;
  name: string;
  icon?: string;
  sortOrder?: number;
}

export interface MenuItem {
  id: string;
  name: string;
  description: string;
  price: number;
  categoryId: string;
  categoryName: string;
  imageUrl: string;
  isVeg: boolean;
  available: boolean;
}

export interface CategoriesResponse {
  success: boolean;
  data: { categories: Category[] };
}

export interface MenuItemsResponse {
  success: boolean;
  data: { items: MenuItem[] };
}

export type VegFilter = 'all' | 'veg' | 'nonveg';
