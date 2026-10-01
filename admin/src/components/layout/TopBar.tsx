import React, { useState } from 'react';
import { useLocation } from 'react-router-dom';
import { Search, Bell, Menu, ShieldAlert } from 'lucide-react';
import { getUser, logout } from '../../features/auth/authService';
import { AnimatePresence, motion } from 'framer-motion';

interface TopBarProps {
  onMenuClick: () => void;
}

export const TopBar: React.FC<TopBarProps> = ({ onMenuClick }) => {
  const user = getUser();
  const displayName = user?.fullName || 'Administrator';
  const location = useLocation();
  const [profileOpen, setProfileOpen] = useState(false);

  const breadcrumbs: Record<string, string> = {
    '/': 'COMMAND DASHBOARD',
    '/issues': 'ISSUE QUEUE',
    '/territories': 'TERRITORY INTELLIGENCE',
    '/departments': 'DEPARTMENT REGISTRY',
    '/users': 'USER REGISTRY',
    '/notifications': 'SYSTEM ALERTS',
    '/settings': 'SYSTEM CONFIGURATION'
  };

  const currentPath = breadcrumbs[location.pathname] || 'CIVICPULSE CORE';

  return (
    <header className="topbar">
      <div className="topbar-left">
        <button className="icon-btn mobile-menu-btn" onClick={onMenuClick} aria-label="Open menu">
          <Menu size={24} />
        </button>
        <div className="system-identifier">CP-SEC-01</div>
        <div className="breadcrumb">
          <span style={{ color: 'var(--text-muted)' }}>NETWORK / </span>
          <span style={{ color: 'var(--cyan)' }}>{currentPath}</span>
        </div>
      </div>
      
      <div className="topbar-actions">
        <button 
          className="search-box-btn" 
          onClick={() => window.dispatchEvent(new KeyboardEvent('keydown', { key: 'k', ctrlKey: true }))}
        >
          <Search size={16} />
          <span>Global Search</span>
          <span className="keyboard-shortcut">Ctrl K</span>
        </button>

        <button className="icon-btn" aria-label="Notifications" style={{ position: 'relative' }}>
          <Bell size={20} aria-hidden="true" />
          <div style={{ position: 'absolute', top: -2, right: -2, width: 8, height: 8, background: 'var(--cyan)', borderRadius: '50%', boxShadow: '0 0 8px var(--cyan)' }} />
        </button>

        <div style={{ position: 'relative' }}>
          <button 
            className="icon-btn" 
            style={{ width: 36, height: 36, borderRadius: '50%', background: 'rgba(34, 211, 238, 0.1)', border: '1px solid rgba(34, 211, 238, 0.3)', color: 'var(--cyan)', fontWeight: 600, fontSize: '13px' }}
            onClick={() => setProfileOpen(!profileOpen)}
            aria-label="Admin Profile Menu"
          >
            {displayName.substring(0, 2).toUpperCase()}
          </button>

          <AnimatePresence>
            {profileOpen && (
              <>
                <div style={{ position: 'fixed', inset: 0, zIndex: 90 }} onClick={() => setProfileOpen(false)} />
                <motion.div 
                  initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 10 }}
                  style={{ 
                    position: 'absolute', top: '100%', right: 0, marginTop: 12, width: 240, 
                    background: 'var(--bg-surface)', border: '1px solid var(--border-light)', 
                    borderRadius: 'var(--radius-md)', boxShadow: 'var(--shadow-lg)', zIndex: 100, overflow: 'hidden'
                  }}
                >
                  <div style={{ padding: '16px', borderBottom: '1px solid var(--border-light)' }}>
                    <div style={{ fontSize: '14px', fontWeight: 600, color: 'var(--text-main)', marginBottom: 4 }}>{displayName}</div>
                    <div style={{ fontSize: '11px', color: 'var(--cyan)', fontFamily: 'var(--font-mono)', letterSpacing: '1px' }}>ADMINISTRATOR</div>
                  </div>
                  <div style={{ padding: '8px' }}>
                    <button style={{ width: '100%', padding: '10px 12px', textAlign: 'left', fontSize: '13px', color: 'var(--text-muted)', borderRadius: 'var(--radius-sm)' }}>Profile</button>
                    <button style={{ width: '100%', padding: '10px 12px', textAlign: 'left', fontSize: '13px', color: 'var(--text-muted)', borderRadius: 'var(--radius-sm)' }}>Security</button>
                    <button 
                      onClick={logout} 
                      style={{ width: '100%', padding: '10px 12px', textAlign: 'left', fontSize: '13px', color: 'var(--danger)', borderRadius: 'var(--radius-sm)', display: 'flex', alignItems: 'center', gap: '8px' }}
                      onMouseEnter={e => e.currentTarget.style.background = 'var(--danger-bg)'}
                      onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
                    >
                      <ShieldAlert size={16} /> Terminate Session
                    </button>
                  </div>
                </motion.div>
              </>
            )}
          </AnimatePresence>
        </div>
      </div>
    </header>
  );
};
