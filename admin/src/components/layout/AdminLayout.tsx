import React, { type ReactNode, useState, useEffect } from 'react';
import { Sidebar } from './Sidebar';
import { TopBar } from './TopBar';
import { CommandPalette } from '../command/CommandPalette';

interface AdminLayoutProps {
  children: ReactNode;
}

export const AdminLayout: React.FC<AdminLayoutProps> = ({ children }) => {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  const toggleMobileMenu = () => setIsMobileMenuOpen(!isMobileMenuOpen);
  const closeMobileMenu = () => setIsMobileMenuOpen(false);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isMobileMenuOpen) {
        closeMobileMenu();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isMobileMenuOpen]);

  return (
    <div className="app-container">
      <div className="bg-grid"></div>
      <CommandPalette />
      
      <Sidebar isOpen={isMobileMenuOpen} onClose={closeMobileMenu} />
      <div className="main-wrapper">
        <TopBar onMenuClick={toggleMobileMenu} />
        <main className="page-content" id="main-content" tabIndex={-1}>
          {children}
        </main>
      </div>
    </div>
  );
};
