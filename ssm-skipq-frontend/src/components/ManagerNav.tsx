import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  ClipboardList,
  UtensilsCrossed,
  MessageSquare,
  User,
} from 'lucide-react';
import styles from './ManagerNav.module.css';

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

const ManagerNav = () => {
  return (
    <>
      <nav className={styles.topNav}>
        {navItems.map(({ to, label, icon: Icon, end }) => (
          <NavLink
            key={to}
            to={to}
            end={end}
            className={({ isActive }) =>
              `${styles.topLink} ${isActive ? styles.linkActive : ''}`
            }
          >
            {({ isActive }) => (
              <>
                <Icon size={18} strokeWidth={isActive ? 2.25 : 1.75} />
                <span>{label}</span>
              </>
            )}
          </NavLink>
        ))}
      </nav>

      <nav className={styles.sideNav}>
        {navItems.map(({ to, label, icon: Icon, end }) => (
          <NavLink
            key={to}
            to={to}
            end={end}
            className={({ isActive }) =>
              `${styles.sideLink} ${isActive ? styles.linkActive : ''}`
            }
          >
            {({ isActive }) => (
              <>
                <Icon size={20} strokeWidth={isActive ? 2.25 : 1.75} />
                <span>{label}</span>
              </>
            )}
          </NavLink>
        ))}
      </nav>
    </>
  );
};

export default ManagerNav;
