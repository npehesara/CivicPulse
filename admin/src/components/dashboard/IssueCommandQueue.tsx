import React from 'react';
import { AlertCircle, ArrowRight } from 'lucide-react';

export const IssueCommandQueue: React.FC = () => {
  const hasData = false;

  return (
    <div className="panel-glass">
      <div className="panel-header">
        <h2 className="panel-title">ISSUE COMMAND QUEUE</h2>
        <button style={{ color: 'var(--cyan)', fontSize: '11px', fontFamily: 'var(--font-mono)', display: 'flex', alignItems: 'center', gap: 4 }}>
          VIEW ALL <ArrowRight size={14} />
        </button>
      </div>
      <div className="hud-panel" style={{ overflowY: 'auto' }}>
        {!hasData ? (
          <div className="empty-matrix" style={{ height: 200 }}>
            <AlertCircle size={24} style={{ marginBottom: 12, opacity: 0.5 }} />
            <span>AWAITING LIVE ISSUE TELEMETRY</span>
          </div>
        ) : (
          <div className="telemetry-list">
            {/* Real items will go here */}
          </div>
        )}
      </div>
    </div>
  );
};
