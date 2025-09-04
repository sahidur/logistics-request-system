import React, { useState, useEffect } from 'react';
import './Admin.css';
import { API_ENDPOINTS } from './config';

function Admin({ token, onLogout }) {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const fetchRequests = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await fetch(API_ENDPOINTS.REQUESTS, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) throw new Error('Failed to fetch requests');
      const data = await res.json();
      setRequests(data);
    } catch (e) {
      setError(e.message);
    }
    setLoading(false);
  };

  const downloadExcel = () => {
    window.open(`${API_ENDPOINTS.EXPORT}?token=${token}`, '_blank');
  };

  useEffect(() => {
    fetchRequests();
  }, []);

  const totalItems = requests.reduce((sum, req) => sum + req.items.length, 0);
  const totalValue = requests.reduce((sum, req) => 
    sum + req.items.reduce((itemSum, item) => itemSum + (item.price * item.quantity), 0), 0
  );

  return (
    <div className="admin-bg">
      <div className="admin-panel">
        <div className="admin-header">
          <h2>Admin Dashboard</h2>
          <div className="admin-actions">
            <button className="excel-btn" onClick={downloadExcel}>
              📊 Export Excel
            </button>
            <button className="logout-btn" onClick={onLogout}>
              🚪 Logout
            </button>
          </div>
        </div>

        <div className="requests-stats">
          <div className="stat-card">
            <div className="stat-value">{requests.length}</div>
            <div className="stat-label">Total Requests</div>
          </div>
          <div className="stat-card">
            <div className="stat-value">{totalItems}</div>
            <div className="stat-label">Total Items</div>
          </div>
          <div className="stat-card">
            <div className="stat-value">৳{totalValue.toFixed(2)}</div>
            <div className="stat-label">Total Value</div>
          </div>
        </div>

        {loading && (
          <div className="loading-spinner">
            <div className="spinner"></div>
            Loading requests...
          </div>
        )}

        {error && <div className="error-msg">❌ {error}</div>}

        {!loading && !error && requests.length === 0 && (
          <div className="empty-state">
            <div className="empty-state-icon">📋</div>
            <div className="empty-state-title">No Requests Yet</div>
            <div className="empty-state-description">
              Logistics requests will appear here once submitted.
            </div>
          </div>
        )}

        <div className="requests-list">
          {requests.map((req) => (
            <div className="request-card" key={req.id}>
              <div className="request-header">
                <div className="request-info">
                  <div className="request-info-label">Requester</div>
                  <div className="request-info-value">{req.user.name}</div>
                </div>
                <div className="request-info">
                  <div className="request-info-label">Email</div>
                  <div className="request-info-value">{req.user.email}</div>
                </div>
                <div className="request-info">
                  <div className="request-info-label">Team</div>
                  <div className="request-info-value">{req.user.teamName || 'Not specified'}</div>
                </div>
                <div className="request-info">
                  <div className="request-info-label">Status</div>
                  <div className={`request-status status-${req.status}`}>
                    {req.status}
                  </div>
                </div>
                <div className="request-info">
                  <div className="request-info-label">Submitted</div>
                  <div className="request-info-value">
                    {new Date(req.createdAt).toLocaleDateString()}
                  </div>
                </div>
              </div>

              <div className="items-section-title">
                📦 Requested Items ({req.items.length})
              </div>
              
              <div className="items-grid">
                {req.items.map((item) => (
                  <div className="item-row" key={item.id}>
                    <div className="item-field">
                      <div className="item-field-label">Item Name</div>
                      <div className="item-field-value">{item.name}</div>
                    </div>
                    <div className="item-field">
                      <div className="item-field-label">Description</div>
                      <div className="item-field-value">{item.description}</div>
                    </div>
                    <div className="item-field">
                      <div className="item-field-label">Quantity</div>
                      <div className="item-field-value">{item.quantity}</div>
                    </div>
                    <div className="item-field">
                      <div className="item-field-label">Price</div>
                      <div className="item-field-value">৳{item.price}</div>
                    </div>
                    <div className="item-field">
                      <div className="item-field-label">Source</div>
                      <div className="item-field-value">{item.source}</div>
                    </div>
                    <div className="item-field">
                      {item.sampleFile && (
                        <a 
                          href={`http://localhost:4000/uploads/${item.sampleFile}`} 
                          target="_blank" 
                          rel="noopener noreferrer" 
                          className="file-link"
                        >
                          📎 View File
                        </a>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

export default Admin;
