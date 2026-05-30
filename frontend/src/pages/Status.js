import React, { useState, useEffect } from 'react';
import { checkHealth } from '../services/api';
import './Status.css';

function Status() {
  const [status, setStatus] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchStatus = async () => {
      try {
        const data = await checkHealth();
        setStatus(data);
      } catch (err) {
        setError('Could not reach backend API');
      } finally {
        setLoading(false);
      }
    };
    fetchStatus();
  }, []);

  return (
    <div className="status-page">
      <h1>API Status</h1>
      <p className="subtitle">Live health check from the Golang backend.</p>

      {loading && <div className="status-card loading">⏳ Checking backend...</div>}

      {error && (
        <div className="status-card error">
          <span className="dot red"></span>
          <div>
            <strong>Backend Unreachable</strong>
            <p>{error}</p>
          </div>
        </div>
      )}

      {status && (
        <div className="status-card success">
          <span className="dot green"></span>
          <div>
            <strong>Backend is Healthy ✅</strong>
            <p>Status: {status.status}</p>
            <p>Environment: {status.environment}</p>
            <p>Version: {status.version}</p>
            <p>Timestamp: {new Date(status.timestamp).toLocaleString()}</p>
          </div>
        </div>
      )}

      <div className="env-info">
        <h3>Frontend Config</h3>
        <p>API URL: <code>{process.env.REACT_APP_API_URL || 'http://localhost:8080'}</code></p>
        <p>Environment: <code>{process.env.REACT_APP_ENV || 'development'}</code></p>
      </div>
    </div>
  );
}

export default Status;
