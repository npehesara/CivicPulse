import { env } from '../../config/env';

export interface OidcConfiguration {
  authorization_endpoint: string;
  token_endpoint: string;
}

export interface TokenResponse {
  access_token: string;
  refresh_token?: string;
  id_token?: string;
  expires_in: number;
}

const getOidcConfiguration = async (): Promise<OidcConfiguration> => {
  return {
    authorization_endpoint: `${env.backendBaseUrl}/oauth2/authorize`,
    token_endpoint: `${env.backendBaseUrl}/oauth2/token`,
  };
};

const generateRandomString = (length: number) => {
  const array = new Uint8Array(length);
  window.crypto.getRandomValues(array);
  return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
};

const generateCodeChallenge = async (codeVerifier: string) => {
  const encoder = new TextEncoder();
  const data = encoder.encode(codeVerifier);
  const digest = await window.crypto.subtle.digest('SHA-256', data);
  const base64Digest = btoa(String.fromCharCode(...new Uint8Array(digest)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
  return base64Digest;
};

export const startLogin = async () => {
  const config = await getOidcConfiguration();
  const state = generateRandomString(16);
  const codeVerifier = generateRandomString(32);
  const codeChallenge = await generateCodeChallenge(codeVerifier);

  sessionStorage.setItem('oauth_state', state);
  sessionStorage.setItem('oauth_code_verifier', codeVerifier);

  const authUrl = new URL(config.authorization_endpoint);
  authUrl.searchParams.append('response_type', 'code');
  authUrl.searchParams.append('client_id', env.adminOAuthClientId);
  authUrl.searchParams.append('redirect_uri', env.adminOAuthRedirectUri);
  authUrl.searchParams.append('scope', 'openid profile offline_access');
  authUrl.searchParams.append('state', state);
  authUrl.searchParams.append('code_challenge', codeChallenge);
  authUrl.searchParams.append('code_challenge_method', 'S256');

  window.location.assign(authUrl.toString());
};

export const handleCallback = async (code: string, state: string) => {
  const savedState = sessionStorage.getItem('oauth_state');
  const codeVerifier = sessionStorage.getItem('oauth_code_verifier');

  if (!savedState || !codeVerifier || state !== savedState) {
    throw new Error('Invalid state or missing verifier');
  }

  sessionStorage.removeItem('oauth_state');
  sessionStorage.removeItem('oauth_code_verifier');

  const config = await getOidcConfiguration();
  const params = new URLSearchParams();
  params.append('grant_type', 'authorization_code');
  params.append('client_id', env.adminOAuthClientId);
  params.append('redirect_uri', env.adminOAuthRedirectUri);
  params.append('code', code);
  params.append('code_verifier', codeVerifier);

  const res = await fetch(config.token_endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params,
  });

  if (!res.ok) {
    const errorData = await res.json();
    throw new Error(errorData.error_description || 'Token exchange failed');
  }

  const tokenData: TokenResponse = await res.json();
  
  // Storing in memory/sessionStorage. For real production, in-memory is better, but requires silent refresh.
  // Using localStorage for simplicity in this demo, but typically in-memory + refresh token in httpOnly cookie is best.
  // Given backend is completely separate and we can't easily do cookies, we use localStorage/sessionStorage.
  sessionStorage.setItem('access_token', tokenData.access_token);
  if (tokenData.refresh_token) {
    localStorage.setItem('refresh_token', tokenData.refresh_token);
  }

  return tokenData;
};

export const logout = () => {
  sessionStorage.removeItem('access_token');
  localStorage.removeItem('refresh_token');
  window.location.replace('/login');
};

export const getAccessToken = () => sessionStorage.getItem('access_token');

export const decodeJwt = (token: string) => {
  try {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(window.atob(base64).split('').map(function(c) {
      return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
    }).join(''));
    return JSON.parse(jsonPayload);
  } catch {
    return null;
  }
};

export const getUser = () => {
  const token = getAccessToken();
  if (!token) return null;
  return decodeJwt(token);
};

export const hasRole = (role: string) => {
  const user = getUser();
  if (!user || !user.roles) return false;
  const roles = Array.isArray(user.roles) ? user.roles : [user.roles];
  return roles.includes(role) || roles.includes(`ROLE_${role}`);
};
