import { api } from './api';
import type { Category, MenuItem } from '../types/menu';

interface ManagerMenuResponse {
  success: boolean;
  data: { categories: Category[]; items: MenuItem[] };
}

interface MenuItemResponse {
  success: boolean;
  data: { item: MenuItem };
}

export const fetchManagerMenu = async () => {
  const { data } = await api.get<ManagerMenuResponse>('/menu/manager/items');
  return data.data;
};

export const createMenuItem = async (formData: FormData) => {
  const { data } = await api.post<MenuItemResponse>('/menu/items', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
  });
  return data.data.item;
};

export const updateMenuItem = async (id: string, formData: FormData) => {
  const { data } = await api.patch<MenuItemResponse>(
    `/menu/items/${id}`,
    formData,
    { headers: { 'Content-Type': 'multipart/form-data' } },
  );
  return data.data.item;
};

export const updateMenuItemPrice = async (id: string, price: number) => {
  const { data } = await api.patch<MenuItemResponse>(
    `/menu/items/${id}/price`,
    { price },
  );
  return data.data.item;
};

export const toggleMenuItemAvailability = async (id: string) => {
  const { data } = await api.patch<MenuItemResponse>(
    `/menu/items/${id}/availability`,
  );
  return data.data.item;
};

export const deleteMenuItem = async (id: string) => {
  await api.delete(`/menu/items/${id}`);
};

interface CategoryResponse {
  success: boolean;
  data: { category: Category };
}

export const createCategory = async (payload: {
  name: string;
  icon: string;
  sortOrder: number;
}) => {
  const { data } = await api.post<CategoryResponse>(
    '/menu/categories',
    payload,
  );
  return data.data.category;
};

export const updateCategory = async (
  id: string,
  payload: { name: string; icon: string; sortOrder: number },
) => {
  const { data } = await api.patch<CategoryResponse>(
    `/menu/categories/${id}`,
    payload,
  );
  return data.data.category;
};

export const deleteCategory = async (id: string) => {
  await api.delete(`/menu/categories/${id}`);
};
