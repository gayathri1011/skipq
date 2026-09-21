import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import StudentShell from './layouts/StudentShell';
import ManagerLayout from './layouts/ManagerLayout';
import SplashPage from './pages/SplashPage';
import StudentLoginPage from './pages/StudentLoginPage';
import ManagerLoginPage from './pages/ManagerLoginPage';
import StudentHomePage from './pages/StudentHomePage';
import StudentCartPage from './pages/StudentCartPage';
import StudentCheckoutPage from './pages/StudentCheckoutPage';
import StudentOrderConfirmationPage from './pages/StudentOrderConfirmationPage';
import StudentTrackOrderPage from './pages/StudentTrackOrderPage';
import StudentProfilePage from './pages/StudentProfilePage';
import ManagerDashboardPage from './pages/ManagerDashboardPage';
import ManagerOrdersPage from './pages/ManagerOrdersPage';
import ManagerMenuPage from './pages/ManagerMenuPage';
import ManagerFeedbackPage from './pages/ManagerFeedbackPage';
import ManagerProfilePage from './pages/ManagerProfilePage';

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/" element={<SplashPage />} />

          <Route path="/student/login" element={<StudentLoginPage />} />
          <Route path="/manager/login" element={<ManagerLoginPage />} />

          <Route element={<ProtectedRoute allowedRole="student" />}>
            <Route element={<StudentShell />}>
              <Route path="/student" element={<StudentHomePage />} />
              <Route path="/student/cart" element={<StudentCartPage />} />
              <Route
                path="/student/checkout"
                element={<StudentCheckoutPage />}
              />
              <Route
                path="/student/order-confirmation"
                element={<StudentOrderConfirmationPage />}
              />
              <Route
                path="/student/track-order/:orderId"
                element={<StudentTrackOrderPage />}
              />
              <Route path="/student/orders" element={<Navigate to="/student" replace />} />
              <Route path="/student/profile" element={<StudentProfilePage />} />
            </Route>
          </Route>

          <Route element={<ProtectedRoute allowedRole="manager" />}>
            <Route element={<ManagerLayout />}>
              <Route path="/manager" element={<ManagerDashboardPage />} />
              <Route path="/manager/orders" element={<ManagerOrdersPage />} />
              <Route path="/manager/menu" element={<ManagerMenuPage />} />
              <Route
                path="/manager/feedback"
                element={<ManagerFeedbackPage />}
              />
              <Route path="/manager/profile" element={<ManagerProfilePage />} />
            </Route>
          </Route>

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
