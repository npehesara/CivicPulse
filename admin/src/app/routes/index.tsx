import { createBrowserRouter } from 'react-router-dom';
import { LoginPage } from '../../features/auth/LoginPage';
import { OAuthCallbackPage } from '../../features/auth/OAuthCallbackPage';
import { AccessDeniedPage } from '../../features/auth/AccessDeniedPage';
import { ProtectedRoute } from '../../features/auth/ProtectedRoute';
import { AdminLayout } from '../../components/layout/AdminLayout';
import { Dashboard } from '../../features/dashboard/Dashboard';

export const router = createBrowserRouter([
  {
    path: '/login',
    element: <LoginPage />,
  },
  {
    path: '/oauth2/callback',
    element: <OAuthCallbackPage />,
  },
  {
    path: '/access-denied',
    element: <AccessDeniedPage />,
  },
  {
    path: '/',
    element: (
      <ProtectedRoute requireAdmin>
        <AdminLayout>
          <Dashboard />
        </AdminLayout>
      </ProtectedRoute>
    ),
  },
  {
    path: '*',
    element: <div>404 Not Found</div>,
  }
]);
