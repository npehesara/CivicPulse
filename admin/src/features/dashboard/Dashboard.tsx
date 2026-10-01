import React, { Suspense } from 'react';
import { motion } from 'framer-motion';
import { Canvas } from '@react-three/fiber';
import { TerritoryMap } from '../../components/3d/TerritoryMap';
import { ActivityMatrix } from '../../components/3d/ActivityMatrix';
import { TelemetryPanel } from '../../components/dashboard/TelemetryPanel';
import { IssueCommandQueue } from '../../components/dashboard/IssueCommandQueue';

export const Dashboard: React.FC = () => {
  const pageVariants = {
    hidden: { opacity: 0, scale: 0.98, y: 10 },
    visible: { opacity: 1, scale: 1, y: 0, transition: { duration: 0.3, staggerChildren: 0.1 } }
  };

  return (
    <motion.div 
      initial="hidden" animate="visible" variants={pageVariants}
      style={{ height: '100%', display: 'flex', flexDirection: 'column' }}
    >
      <div style={{ marginBottom: 24 }}>
        <h1 style={{ fontFamily: 'var(--font-display)', fontSize: 24, fontWeight: 700, letterSpacing: '2px', color: '#fff' }}>
          LIVE TERRITORIAL OVERVIEW
        </h1>
        <div style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--cyan)', letterSpacing: '2px', display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 6, height: 6, borderRadius: '50%', background: 'var(--cyan)', boxShadow: '0 0 8px var(--cyan)' }} />
          SYSTEM ONLINE • AWAITING TELEMETRY
        </div>
      </div>

      <div className="dashboard-grid">
        {/* Large 3D Map */}
        <div className="panel-glass map-container-main">
          <div className="panel-header">
            <h2 className="panel-title">CIVIC NETWORK TOPOLOGY</h2>
            <div style={{ fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--text-muted)' }}>LAT 7.87 / LNG 80.77</div>
          </div>
          <div style={{ flex: 1, position: 'relative' }}>
            <div style={{ position: 'absolute', inset: 0, zIndex: 1 }}>
              <Suspense fallback={
                <div className="empty-matrix">
                  <div style={{ color: 'var(--cyan)', marginBottom: 8 }}>INITIALIZING GEO ENGINE...</div>
                  <div className="scan-line" style={{ height: 1 }}></div>
                </div>
              }>
                <Canvas camera={{ position: [0, 4, 8], fov: 45 }}>
                  <TerritoryMap />
                </Canvas>
              </Suspense>
            </div>
            
            {/* Map UI Overlay */}
            <div style={{ position: 'absolute', bottom: 20, left: 20, zIndex: 2, pointerEvents: 'none' }}>
              <div style={{ fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--text-muted)', marginBottom: 4 }}>DATA LAYER</div>
              <div style={{ fontSize: 13, color: '#fff', fontWeight: 600 }}>SRI LANKA (PLACEHOLDER)</div>
            </div>
          </div>
        </div>

        {/* Top Right: Telemetry */}
        <TelemetryPanel />

        {/* Bottom Right: Issue Queue */}
        <IssueCommandQueue />

        {/* Bottom Left: Activity Matrix */}
        <div className="panel-glass" style={{ gridColumn: '1 / 2', gridRow: '3 / 4', height: 300 }}>
          <div className="panel-header">
            <h2 className="panel-title">CIVIC ACTIVITY MATRIX</h2>
          </div>
          <div style={{ flex: 1, position: 'relative' }}>
            <Suspense fallback={<div className="empty-matrix">LOADING MATRIX...</div>}>
              <Canvas camera={{ position: [10, 5, 10], fov: 30 }}>
                <ActivityMatrix />
              </Canvas>
            </Suspense>
          </div>
        </div>
      </div>
    </motion.div>
  );
};
