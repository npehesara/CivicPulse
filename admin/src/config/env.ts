export const env = {
  backendBaseUrl: import.meta.env.VITE_API_BASE_URL || 'https://civicpulse-backend-cezi.onrender.com',
  adminOAuthClientId: import.meta.env.VITE_ADMIN_OAUTH_CLIENT_ID || 'civicpulse-admin-web-client',
  adminOAuthRedirectUri: import.meta.env.VITE_ADMIN_OAUTH_REDIRECT_URI || 'http://localhost:5173/oauth2/callback',
};