import React from 'react';
import { logout } from './authService';

export const AccessDeniedPage: React.FC = () => {
  return (
    <div className="login-cinematic">
      <div className="bg-grid"></div>
      <div className="login-ui-layer">
        <div className="login-center-box">
          <h1 className="login-title" style={{ fontSize: 32, color: 'var(--danger)' }}>ACCESS DENIED</h1>
          <div className="login-subtitle">UNAUTHORIZED PERSONNEL</div>
          <p style={{ color: 'var(--text-muted)', marginBottom: 32, fontFamily: 'var(--font-mono)', maxWidth: 400 }}>
            Your clearance level does not permit access to the Civic Intelligence Command Center.
          </p>
          <button onClick={logout} className="enter-btn" style={{ borderColor: 'var(--danger)', color: 'var(--danger)' }}>
            TERMINATE SESSION
          </button>
        </div>
      </div>
    </div>
  );
};
