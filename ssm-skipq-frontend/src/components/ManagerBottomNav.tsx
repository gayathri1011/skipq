import { NavLink } from 'react-router-dom';
import {
  ClipboardList,
  LayoutDashboard,
  MessageSquare,
  UtensilsCrossed,
  User,
} from 'lucide-react';
import styles from './ManagerBottomNav.module.css';

const navItems = [
  { to: '/manager', label: 'Dashboard', icon: LayoutDashboard, end: true },
  { to: '/manager/orders', label: 'Orders', icon: ClipboardList, end: false },
  { to: '/manager/menu', label: 'Master', icon: UtensilsCrossed, end: false },
  {
    to: '/manager/feedback',
    label: 'Feedback',
    icon: MessageSquare,
    end: false,
  },
  { to: '/manager/profile', label: 'Profile', icon: User, end: false },
];

const ManagerBottomNav = () => (
  <nav className={styles.nav}>
    {navItems.map(({ to, label, icon: Icon, end }) => (
      <NavLink
        key={to}
        to={to}
        end={end}
        className={({ isActive }) =>
          `${styles.link} ${isActive ? styles.linkActive : ''}`
        }
      >
        {({ isActive }) => (
          <>
            <Icon size={22} strokeWidth={isActive ? 2.25 : 1.75} />
            <span className={styles.label}>{label}</span>
          </>
        )}
      </NavLink>
    ))}
  </nav>
);

export default ManagerBottomNav;
