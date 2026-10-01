import React, { useState } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { LayoutDashboard, AlertCircle, Map, Building2, Users, Bell, Settings, X, ShieldCheck, ChevronRight, ChevronLeft } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

interface SidebarProps {
  isOpen: boolean;
  onClose: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ isOpen, onClose }) => {
  const [isExpanded, setIsExpanded] = useState(() => {
    return localStorage.getItem('sidebarExpanded') === 'true';
  });
  const [hoveredItem, setHoveredItem] = useState<string | null>(null);
  const location = useLocation();

  const toggleExpand = () => {
    const nextState = !isExpanded;
    setIsExpanded(nextState);
    localStorage.setItem('sidebarExpanded', String(nextState));
  };

  const navItems = [
    { name: 'Dashboard', path: '/', icon: <LayoutDashboard size={20} aria-hidden="true" />, tooltip: 'COMMAND DASHBOARD' },
    { name: 'Issues', path: '/issues', icon: <AlertCircle size={20} aria-hidden="true" />, tooltip: 'ISSUE QUEUE' },
    { name: 'Territories', path: '/territories', icon: <Map size={20} aria-hidden="true" />, tooltip: 'TERRITORY INTEL' },
    { name: 'Departments', path: '/departments', icon: <Building2 size={20} aria-hidden="true" />, tooltip: 'DEPARTMENTS' },
    { name: 'Users', path: '/users', icon: <Users size={20} aria-hidden="true" />, tooltip: 'USER REGISTRY' },
    { name: 'Notifications', path: '/notifications', icon: <Bell size={20} aria-hidden="true" />, tooltip: 'ALERTS' },
    { name: 'Settings', path: '/settings', icon: <Settings size={20} aria-hidden="true" />, tooltip: 'SYSTEM CONFIG' },
  ];

  return (
    <>
      <AnimatePresence>
        {isOpen && (
          <motion.div 
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            className="sidebar-backdrop" onClick={onClose} aria-hidden="true"
          />
        )}
      </AnimatePresence>
      <aside className={`sidebar ${isOpen ? 'open' : ''} ${isExpanded ? 'expanded' : ''}`} aria-label="Main Navigation">
        
        <div className="sidebar-header">
          <ShieldCheck size={28} style={{ color: 'var(--cyan)' }} aria-hidden="true" />
          <AnimatePresence>
            {isExpanded && (
              <motion.span 
                initial={{ opacity: 0, width: 0 }} animate={{ opacity: 1, width: 'auto' }} exit={{ opacity: 0, width: 0 }}
                style={{ marginLeft: 12, fontWeight: 700, letterSpacing: '1px', whiteSpace: 'nowrap', overflow: 'hidden' }}
              >
                CIVICPULSE
              </motion.span>
            )}
          </AnimatePresence>
          <button className="icon-btn mobile-close-btn" onClick={onClose} aria-label="Close menu">
            <X size={24} color="#fff" />
          </button>
        </div>

        <nav className="sidebar-nav">
          {navItems.map((item) => {
            const isActive = location.pathname === item.path || (item.path !== '/' && location.pathname.startsWith(item.path));
            return (
              <div 
                key={item.name} 
                style={{ position: 'relative', width: isExpanded ? '100%' : 'auto', padding: isExpanded ? '0 12px' : 0 }}
                onMouseEnter={() => setHoveredItem(item.name)}
                onMouseLeave={() => setHoveredItem(null)}
              >
                <NavLink 
                  to={item.path} 
                  onClick={onClose}
                  className={`nav-item ${isActive ? 'active' : ''}`}
                >
                  {item.icon}
                  <AnimatePresence>
                    {isExpanded && (
                      <motion.span 
                        initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -10 }}
                        style={{ fontSize: '13px', fontWeight: 500, letterSpacing: '0.5px' }}
                      >
                        {item.name}
                      </motion.span>
                    )}
                  </AnimatePresence>
                  {isActive && (
                    <>
                      <motion.div 
                        layoutId="sidebar-active-bg"
                        className="active-bg" 
                        style={{ position: 'absolute', inset: 0, background: 'var(--bg-surface-active)', borderRadius: 'var(--radius-md)', zIndex: -1 }}
                      />
                      <motion.div 
                        layoutId="sidebar-active-indicator"
                        className="active-indicator"
                      />
                    </>
                  )}
                </NavLink>

                {/* Futuristic Tooltip */}
                <AnimatePresence>
                  {!isExpanded && hoveredItem === item.name && (
                    <motion.div 
                      initial={{ opacity: 0, x: -5 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -5 }}
                      className="sidebar-tooltip"
                    >
                      {item.tooltip}
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            );
          })}
        </nav>

        {/* Expand Toggle */}
        <button 
          onClick={toggleExpand} 
          className="icon-btn" 
          style={{ position: 'absolute', bottom: '24px', left: '50%', transform: 'translateX(-50%)', display: 'flex' }}
          aria-label={isExpanded ? "Collapse sidebar" : "Expand sidebar"}
        >
          {isExpanded ? <ChevronLeft size={20} /> : <ChevronRight size={20} />}
        </button>
      </aside>
    </>
  );
};
