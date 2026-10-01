import React from 'react';
import { Navigate } from 'react-router-dom';
import { getAccessToken, hasRole } from './authService';

interface ProtectedRouteProps {
  children: React.ReactNode;
  requireAdmin?: boolean;
}

export const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ children, requireAdmin = false }) => {
  const token = getAccessToken();

  if (!token) {
    return <Navigate to="/login" replace />;
  }

  if (requireAdmin && !hasRole('ADMIN')) {
    return <Navigate to="/access-denied" replace />;
  }

  return <>{children}</>;
};
