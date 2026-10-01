import React, { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { handleCallback } from './authService';

export const OAuthCallbackPage: React.FC = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const [error, setError] = useState('');

  useEffect(() => {
    const processCallback = async () => {
      const code = searchParams.get('code');
      const state = searchParams.get('state');
      const errorParam = searchParams.get('error');

      if (errorParam) {
        setError(searchParams.get('error_description') || 'Access denied');
        return;
      }

      if (!code || !state) {
        setError('Invalid callback parameters');
        return;
      }

      try {
        await handleCallback(code, state);
        navigate('/', { replace: true });
      } catch (err: any) {
        setError(err.message || 'Failed to complete authentication');
      }
    };

    processCallback();
  }, [navigate, searchParams]);

  if (error) {
    return (
      <div className="login-cinematic">
        <div className="bg-grid"></div>
        <div className="login-ui-layer">
          <div className="login-center-box">
            <h1 className="login-title" style={{ fontSize: 32, color: 'var(--danger)' }}>ERROR</h1>
            <div className="login-subtitle">AUTHENTICATION FAILED</div>
            <p style={{ color: 'var(--text-muted)', marginBottom: 24, fontFamily: 'var(--font-mono)' }}>{error}</p>
            <button onClick={() => navigate('/login')} className="enter-btn">RETURN TO LOGIN</button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="login-cinematic">
      <div className="bg-grid"></div>
      <div className="login-ui-layer">
        <div className="login-center-box">
          <div style={{
            width: '48px', height: '48px', border: '2px solid rgba(34, 211, 238, 0.2)', 
            borderTopColor: 'var(--cyan)', borderRadius: '50%', animation: 'spin 1s linear infinite',
            marginBottom: 24
          }}></div>
          <div className="login-subtitle" style={{ marginBottom: 0 }}>AUTHORIZING...</div>
          <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
        </div>
      </div>
    </div>
  );
};
