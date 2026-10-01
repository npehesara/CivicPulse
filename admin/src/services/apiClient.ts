import { env } from '../config/env';
import { getAccessToken, logout } from '../features/auth/authService';

export const apiClient = async (endpoint: string, options: RequestInit = {}) => {
  const token = getAccessToken();
  const headers = new Headers(options.headers || {});
  
  if (token) {
    headers.set('Authorization', `Bearer ${token}`);
  }
  
  headers.set('Content-Type', 'application/json');

  const res = await fetch(`${env.backendBaseUrl}${endpoint}`, {
    ...options,
    headers,
  });

  if (res.status === 401) {
    // Basic handle: logout on 401. A real implementation would try to refresh here.
    logout();
    throw new Error('Unauthorized');
  }

  if (!res.ok) {
    throw new Error('API Request failed');
  }

  return res.json();
};
