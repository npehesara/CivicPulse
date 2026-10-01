import React from 'react';
import { Activity } from 'lucide-react';

export const TelemetryPanel: React.FC = () => {
  return (
    <div className="panel-glass">
      <div className="panel-header">
        <h2 className="panel-title">LIVE TELEMETRY</h2>
      </div>
      <div className="hud-panel" style={{ height: '100%', position: 'relative' }}>
        <div className="empty-matrix">
          <Activity size={32} style={{ marginBottom: 16, color: 'var(--cyan)', opacity: 0.5 }} />
          <span>WAITING FOR DATA STREAM</span>
        </div>
        <div className="scan-line"></div>
      </div>
    </div>
  );
};
