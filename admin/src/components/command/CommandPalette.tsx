import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { LayoutDashboard, AlertCircle, Map, Building2, Users, Bell, Settings, LogOut, ChevronRight } from 'lucide-react';
import { logout } from '../../features/auth/authService';

export const CommandPalette: React.FC = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [query, setQuery] = useState('');
  const [selectedIndex, setSelectedIndex] = useState(0);
  const navigate = useNavigate();

  const commands = [
    { id: 'dashboard', label: 'Go to Dashboard', icon: <LayoutDashboard size={18} />, action: () => navigate('/') },
    { id: 'issues', label: 'Open Issue Queue', icon: <AlertCircle size={18} />, action: () => navigate('/issues') },
    { id: 'territories', label: 'Open Territory Explorer', icon: <Map size={18} />, action: () => navigate('/territories') },
    { id: 'departments', label: 'Open Departments', icon: <Building2 size={18} />, action: () => navigate('/departments') },
    { id: 'users', label: 'Manage Users', icon: <Users size={18} />, action: () => navigate('/users') },
    { id: 'notifications', label: 'View Notifications', icon: <Bell size={18} />, action: () => navigate('/notifications') },
    { id: 'settings', label: 'System Settings', icon: <Settings size={18} />, action: () => navigate('/settings') },
    { id: 'logout', label: 'Log Out', icon: <LogOut size={18} />, action: logout },
  ];

  const filteredCommands = commands.filter(cmd => cmd.label.toLowerCase().includes(query.toLowerCase()));

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        setIsOpen(prev => !prev);
      }
      if (e.key === 'Escape' && isOpen) {
        setIsOpen(false);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen]);

  const handleQueryChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setQuery(e.target.value);
    setSelectedIndex(0);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setSelectedIndex(prev => (prev + 1) % filteredCommands.length);
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setSelectedIndex(prev => (prev - 1 + filteredCommands.length) % filteredCommands.length);
    } else if (e.key === 'Enter') {
      e.preventDefault();
      if (filteredCommands[selectedIndex]) {
        filteredCommands[selectedIndex].action();
        setIsOpen(false);
      }
    }
  };

  if (!isOpen) return null;

  return (
    <div className="cmd-overlay" onClick={() => setIsOpen(false)}>
      <div className="cmd-palette" onClick={e => e.stopPropagation()}>
        <div style={{ position: 'relative' }}>
          <ChevronRight size={20} style={{ position: 'absolute', top: 20, left: 20, color: 'var(--cyan)' }} />
          <input
            autoFocus
            type="text"
            className="cmd-input"
            style={{ paddingLeft: 48 }}
            placeholder="Type a command or search..."
            value={query}
            onChange={handleQueryChange}
            onKeyDown={handleKeyDown}
          />
        </div>
        <div className="cmd-list">
          {filteredCommands.map((cmd, i) => (
            <div
              key={cmd.id}
              className={`cmd-item ${i === selectedIndex ? 'selected' : ''}`}
              onClick={() => {
                cmd.action();
                setIsOpen(false);
              }}
              onMouseEnter={() => setSelectedIndex(i)}
            >
              {cmd.icon}
              <span style={{ fontSize: '14px' }}>{cmd.label}</span>
            </div>
          ))}
          {filteredCommands.length === 0 && (
            <div style={{ padding: '24px', textAlign: 'center', color: 'var(--text-muted)' }}>
              No commands found.
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
