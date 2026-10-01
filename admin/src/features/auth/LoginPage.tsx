import React, { useState, Suspense } from 'react';
import { startLogin } from './authService';
import { Canvas } from '@react-three/fiber';
import { DigitalGlobe } from '../../components/3d/DigitalGlobe';

export const LoginPage: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async () => {
    try {
      setLoading(true);
      setError('');
      await startLogin();
    } catch (err: any) {
      console.error('Login error:', err);
      setError(err.message || 'Failed to initialize secure link');
      setLoading(false);
    }
  };

  return (
    <div className="login-cinematic">
      {/* 3D Background */}
      <div style={{ position: 'absolute', inset: 0, zIndex: 1 }}>
        <Suspense fallback={null}>
          <Canvas camera={{ position: [0, 0, 8], fov: 45 }}>
            <DigitalGlobe />
          </Canvas>
        </Suspense>
      </div>

      {/* Grid overlay */}
      <div className="bg-grid"></div>

      {/* UI Layer */}
      <div className="login-ui-layer">
        
        {/* HUD Elements */}
        <div className="hud-labels">
          <div className="hud-corner hud-tl"></div>
          <div className="hud-corner hud-tr"></div>
          <div className="hud-corner hud-bl"></div>
          <div className="hud-corner hud-br"></div>
          <div className="hud-text hud-text-tl">SYS.ID // CP-ADMIN-01</div>
          <div className="hud-text hud-text-br">STATUS // SECURE ACCESS REQUIRED</div>
        </div>

        {/* Center Box */}
        <div className="login-center-box">
          <div style={{
            display: 'inline-block',
            padding: '4px 12px',
            border: '1px solid rgba(34, 211, 238, 0.3)',
            color: 'var(--cyan)',
            fontFamily: 'var(--font-mono)',
            fontSize: '12px',
            letterSpacing: '2px',
            marginBottom: '24px',
            background: 'rgba(34, 211, 238, 0.05)',
            borderRadius: 'var(--radius-sm)'
          }}>
            AUTHORIZATION REQUIRED
          </div>
          
          <h1 className="login-title">CIVICPULSE</h1>
          <div className="login-subtitle">CIVIC INTELLIGENCE NETWORK</div>
          
          <p style={{
            color: 'var(--text-muted)',
            fontFamily: 'var(--font-mono)',
            fontSize: '12px',
            letterSpacing: '1px',
            marginBottom: '48px',
            opacity: 0.7
          }}>
            MONITOR • ANALYZE • RESPOND
          </p>
          
          {error && (
            <div style={{ 
              color: 'var(--danger)', 
              fontFamily: 'var(--font-mono)', 
              fontSize: '12px', 
              marginBottom: '24px',
              padding: '8px 16px',
              background: 'var(--danger-bg)',
              border: '1px solid rgba(251, 113, 133, 0.3)'
            }}>
              [ERR] {error}
            </div>
          )}

          <button
            type="button"
            onClick={handleLogin}
            disabled={loading}
            className="enter-btn"
          >
            {loading ? 'INITIALIZING LINK...' : 'ENTER COMMAND CENTER'}
          </button>
        </div>
      </div>
    </div>
  );
};
