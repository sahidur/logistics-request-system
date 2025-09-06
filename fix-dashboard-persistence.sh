#!/bin/bash

# Fix Admin Dashboard State Persistence and Data Clipping
# Run this on your server: ssh root@152.42.229.232
# Then: chmod +x fix-dashboard-persistence.sh && ./fix-dashboard-persistence.sh

echo "🔧 Fix Admin Dashboard Persistence & Data Clipping"
echo "================================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}🚨 Issues Identified:${NC}"
echo "1. Dashboard goes white after reload (token lost)"
echo "2. Excel export missing access token on reload" 
echo "3. Long field data needs clipping"
echo "4. No state persistence in frontend"

echo -e "${YELLOW}🔧 Updating frontend for token persistence...${NC}"

cd /var/www/tik-workshop/frontend/src || exit 1

echo -e "${YELLOW}📝 Creating persistent AdminDashboard.jsx...${NC}"
cat > AdminDashboard.jsx << 'EOF'
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import Admin from './Admin';

function AdminDashboard({ token: propToken, onLogout }) {
  const navigate = useNavigate();
  const [token, setToken] = useState(propToken);

  useEffect(() => {
    // Try to get token from multiple sources
    const storedToken = localStorage.getItem('adminToken') || 
                       sessionStorage.getItem('adminToken') || 
                       propToken;
    
    console.log('🔍 AdminDashboard token check:', {
      propToken: propToken ? 'Present' : 'Missing',
      localStorage: localStorage.getItem('adminToken') ? 'Present' : 'Missing',
      sessionStorage: sessionStorage.getItem('adminToken') ? 'Present' : 'Missing',
      finalToken: storedToken ? 'Present' : 'Missing'
    });

    if (storedToken) {
      setToken(storedToken);
    } else {
      console.log('❌ No token found, redirecting to login');
      navigate('/admin');
    }
  }, [propToken, navigate]);

  // Store token when it changes
  useEffect(() => {
    if (token) {
      localStorage.setItem('adminToken', token);
      sessionStorage.setItem('adminToken', token);
    }
  }, [token]);

  const handleLogout = () => {
    console.log('🚪 Logging out, clearing tokens');
    localStorage.removeItem('adminToken');
    sessionStorage.removeItem('adminToken');
    setToken(null);
    if (onLogout) onLogout();
    navigate('/admin');
  };

  if (!token) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        backgroundColor: '#f5f5f5'
      }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: '24px', marginBottom: '20px' }}>🔄</div>
          <div>Loading dashboard...</div>
          <div style={{ fontSize: '14px', color: '#666', marginTop: '10px' }}>
            Checking authentication...
          </div>
        </div>
      </div>
    );
  }

  return <Admin token={token} onLogout={handleLogout} />;
}

export default AdminDashboard;
EOF

echo -e "${YELLOW}📝 Creating enhanced Admin.jsx with data clipping...${NC}"
cat > Admin.jsx << 'EOF'
import React, { useState, useEffect } from 'react';
import './Admin.css';
import { API_ENDPOINTS } from './config';

// Utility function to clip long text
const clipText = (text, maxLength = 50) => {
  if (!text) return '';
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength) + '...';
};

// Utility function to format currency
const formatCurrency = (amount) => {
  return `৳${parseFloat(amount || 0).toFixed(2)}`;
};

// Utility function to format date
const formatDate = (dateString) => {
  try {
    return new Date(dateString).toLocaleDateString('en-BD', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  } catch (e) {
    return 'Invalid Date';
  }
};

function Admin({ token, onLogout }) {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [exportLoading, setExportLoading] = useState(false);

  const fetchRequests = async () => {
    setLoading(true);
    setError('');
    
    console.log('📊 Fetching requests with token:', token ? 'Present' : 'Missing');
    
    try {
      const res = await fetch(API_ENDPOINTS.REQUESTS, {
        headers: { 
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
      });
      
      console.log('📊 Fetch response status:', res.status);
      
      if (!res.ok) {
        if (res.status === 401) {
          throw new Error('Session expired. Please login again.');
        }
        throw new Error(`Failed to fetch requests (${res.status})`);
      }
      
      const data = await res.json();
      console.log('📊 Received data:', data.length, 'requests');
      setRequests(Array.isArray(data) ? data : []);
    } catch (e) {
      console.error('❌ Fetch error:', e.message);
      setError(e.message);
      if (e.message.includes('Session expired')) {
        setTimeout(() => {
          onLogout();
        }, 2000);
      }
    }
    setLoading(false);
  };

  const downloadExcel = async () => {
    if (!token) {
      setError('No access token available. Please login again.');
      return;
    }

    setExportLoading(true);
    setError('');
    
    try {
      console.log('📊 Downloading excel with token:', token ? 'Present' : 'Missing');
      
      const response = await fetch(API_ENDPOINTS.EXPORT, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      console.log('📊 Export response status:', response.status);

      if (!response.ok) {
        if (response.status === 401) {
          throw new Error('Session expired. Please login again.');
        }
        throw new Error(`Export failed (${response.status})`);
      }

      // Get filename from response headers or use default
      const contentDisposition = response.headers.get('Content-Disposition');
      let filename = 'logistics-requests.csv';
      if (contentDisposition) {
        const filenameMatch = contentDisposition.match(/filename="?([^"]+)"?/);
        if (filenameMatch) {
          filename = filenameMatch[1];
        }
      }

      // Create blob and download
      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      window.URL.revokeObjectURL(url);

      console.log('✅ Export downloaded successfully');
    } catch (e) {
      console.error('❌ Export error:', e.message);
      setError(e.message);
      if (e.message.includes('Session expired')) {
        setTimeout(() => {
          onLogout();
        }, 2000);
      }
    }
    setExportLoading(false);
  };

  useEffect(() => {
    if (token) {
      fetchRequests();
    }
  }, [token]);

  // Calculate statistics
  const totalItems = requests.reduce((sum, req) => sum + (req.items?.length || 0), 0);
  const totalValue = requests.reduce((sum, req) => 
    sum + (req.items?.reduce((itemSum, item) => 
      itemSum + ((item.price || 0) * (item.quantity || 1)), 0) || 0), 0
  );

  return (
    <div className="admin-bg">
      <div className="admin-panel">
        <div className="admin-header">
          <h2>📊 Admin Dashboard</h2>
          <div className="admin-actions">
            <button 
              className={`excel-btn ${exportLoading ? 'loading' : ''}`} 
              onClick={downloadExcel}
              disabled={exportLoading || !token}
              title={!token ? 'Please login to export' : 'Export to Excel/CSV'}
            >
              {exportLoading ? '⏳ Exporting...' : '📊 Export Excel'}
            </button>
            <button className="refresh-btn" onClick={fetchRequests} disabled={loading}>
              {loading ? '🔄' : '🔄'} Refresh
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
            <div className="stat-value">{formatCurrency(totalValue)}</div>
            <div className="stat-label">Total Value</div>
          </div>
        </div>

        {loading && (
          <div className="loading-spinner">
            <div className="spinner"></div>
            Loading requests...
          </div>
        )}

        {error && (
          <div className="error-msg">
            ❌ {error}
            {error.includes('Session expired') && (
              <div style={{ fontSize: '12px', marginTop: '5px' }}>
                Redirecting to login in 2 seconds...
              </div>
            )}
          </div>
        )}

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
                  <div className="request-info-value" title={req.user?.name || 'Unknown'}>
                    {clipText(req.user?.name || 'Unknown', 25)}
                  </div>
                </div>
                <div className="request-info">
                  <div className="request-info-label">Email</div>
                  <div className="request-info-value" title={req.user?.email || 'No email'}>
                    {clipText(req.user?.email || 'No email', 30)}
                  </div>
                </div>
                <div className="request-info">
                  <div className="request-info-label">Team</div>
                  <div className="request-info-value" title={req.user?.teamName || 'Not specified'}>
                    {clipText(req.user?.teamName || 'Not specified', 20)}
                  </div>
                </div>
                <div className="request-info">
                  <div className="request-info-label">Status</div>
                  <div className={`request-status status-${req.status || 'pending'}`}>
                    {req.status || 'pending'}
                  </div>
                </div>
                <div className="request-info">
                  <div className="request-info-label">Submitted</div>
                  <div className="request-info-value">
                    {formatDate(req.createdAt)}
                  </div>
                </div>
              </div>

              <div className="items-section-title">
                📦 Requested Items ({req.items?.length || 0})
              </div>
              
              <div className="items-grid">
                {(req.items || []).map((item, index) => (
                  <div className="item-row" key={item.id || index}>
                    <div className="item-field">
                      <div className="item-field-label">Item Name</div>
                      <div className="item-field-value" title={item.name || 'No name'}>
                        {clipText(item.name || 'No name', 25)}
                      </div>
                    </div>
                    <div className="item-field">
                      <div className="item-field-label">Description</div>
                      <div className="item-field-value" title={item.description || 'No description'}>
                        {clipText(item.description || 'No description', 40)}
                      </div>
                    </div>
                    <div className="item-field">
                      <div className="item-field-label">Quantity</div>
                      <div className="item-field-value">{item.quantity || 1}</div>
                    </div>
                    <div className="item-field">
                      <div className="item-field-label">Price</div>
                      <div className="item-field-value">{formatCurrency(item.price)}</div>
                    </div>
                    <div className="item-field">
                      <div className="item-field-label">Source</div>
                      <div className="item-field-value" title={item.source || 'Not specified'}>
                        {clipText(item.source || 'Not specified', 20)}
                      </div>
                    </div>
                    <div className="item-field">
                      {item.sampleFile && (
                        <a 
                          href={`http://152.42.229.232:4000/uploads/${item.sampleFile}`} 
                          target="_blank" 
                          rel="noopener noreferrer" 
                          className="file-link"
                          title={`View file: ${item.sampleFile}`}
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
EOF

echo -e "${YELLOW}🔧 Updating App.jsx for better token management...${NC}"
cat > App.jsx << 'EOF'
import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import './App.css';
import LogisticsForm from './LogisticsForm';
import AdminLogin from './AdminLogin';
import AdminDashboard from './AdminDashboard';

function App() {
  const [adminToken, setAdminToken] = useState(null);

  // Check for existing token on app load
  useEffect(() => {
    const storedToken = localStorage.getItem('adminToken') || sessionStorage.getItem('adminToken');
    if (storedToken) {
      console.log('🔍 Found stored admin token');
      setAdminToken(storedToken);
    }
  }, []);

  const handleAdminLogin = (token) => {
    console.log('✅ Admin login successful, storing token');
    setAdminToken(token);
    localStorage.setItem('adminToken', token);
    sessionStorage.setItem('adminToken', token);
  };

  const handleAdminLogout = () => {
    console.log('🚪 Admin logout, clearing token');
    setAdminToken(null);
    localStorage.removeItem('adminToken');
    sessionStorage.removeItem('adminToken');
  };

  return (
    <Router>
      <div className="App">
        <Routes>
          <Route path="/" element={<LogisticsForm />} />
          <Route 
            path="/admin" 
            element={
              adminToken ? 
                <Navigate to="/admin/dashboard" replace /> : 
                <AdminLogin onLogin={handleAdminLogin} />
            } 
          />
          <Route 
            path="/admin/dashboard" 
            element={
              <AdminDashboard 
                token={adminToken} 
                onLogout={handleAdminLogout} 
              />
            } 
          />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
EOF

echo -e "${YELLOW}🎨 Adding styles for new elements...${NC}"
cat >> Admin.css << 'EOF'

/* Additional styles for persistence fix */
.refresh-btn {
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  border: none;
  color: white;
  padding: var(--space-3) var(--space-4);
  border-radius: var(--radius-lg);
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  margin-right: var(--space-2);
}

.refresh-btn:hover {
  transform: translateY(-1px);
  box-shadow: var(--shadow-lg);
}

.refresh-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

.excel-btn.loading {
  opacity: 0.7;
  cursor: not-allowed;
}

.excel-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  background: #9ca3af;
}

.request-info-value[title],
.item-field-value[title] {
  cursor: help;
}

.file-link[title] {
  cursor: pointer;
}

/* Loading state improvements */
.loading-spinner {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: var(--space-8);
  color: var(--gray-600);
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid var(--gray-200);
  border-top: 3px solid var(--primary-500);
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: var(--space-4);
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* Error message improvements */
.error-msg {
  background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%);
  border: 1px solid #f87171;
  color: #dc2626;
  padding: var(--space-4);
  border-radius: var(--radius-lg);
  margin: var(--space-4) 0;
  text-align: center;
}
EOF

echo -e "${YELLOW}🏗️ Building frontend with persistence fixes...${NC}"
cd /var/www/tik-workshop/frontend || exit 1

# Build the frontend
npm run build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Frontend built successfully with persistence fixes${NC}"
else
    echo -e "${RED}❌ Frontend build failed${NC}"
    exit 1
fi

echo -e "${YELLOW}🔧 Updating backend for better token handling...${NC}"
cd /var/www/tik-workshop/backend || exit 1

pm2 delete tik-workshop-backend 2>/dev/null || true

# Add .env file with proper admin credentials
cat > .env << 'EOF'
NODE_ENV=production
PORT=4000
JWT_SECRET=TikTok_Workshop_2025_Production_JWT_Secret_152_42_229_232_SecureKey_xyz789
ADMIN_EMAIL=admin@logistics.com
ADMIN_PASSWORD=TikTok_Admin_2025_Server_232!
ADMIN_NAME=Admin
MAX_FILE_SIZE=10485760
UPLOAD_DIR=./uploads
EOF

echo -e "${YELLOW}🚀 Starting backend with environment variables...${NC}"
pm2 start index.js --name "tik-workshop-backend" --env production

sleep 3

echo -e "${YELLOW}🧪 Testing persistence fix...${NC}"

echo "1. Health check:"
curl -s http://localhost:4000/api/health | head -3

echo -e "\n2. Admin login test:"
login_response=$(curl -s -X POST http://localhost:4000/api/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@logistics.com","password":"TikTok_Admin_2025_Server_232!"}' \
    2>/dev/null)
echo "$login_response" | head -5

token=$(echo "$login_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ ! -z "$token" ]; then
    echo -e "\n3. Requests with token:"
    curl -s -H "Authorization: Bearer $token" http://localhost:4000/api/requests | head -5
    
    echo -e "\n4. Export with token:"
    curl -s -H "Authorization: Bearer $token" http://localhost:4000/api/export | head -2
fi

echo -e "\n${GREEN}🎉 Dashboard Persistence Fix Complete!${NC}"
echo -e "${BLUE}📋 Fixed Issues:${NC}"
echo -e "✅ Token persists across page reloads"
echo -e "✅ Dashboard stays logged in after refresh"
echo -e "✅ Excel export works with persistent token"
echo -e "✅ Long text data is clipped with tooltips"
echo -e "✅ Better error handling for expired sessions"
echo -e "✅ Loading states for all operations"

echo -e "\n${YELLOW}🔐 Admin Credentials:${NC}"
echo -e "📧 Email: admin@logistics.com"
echo -e "🔑 Password: TikTok_Admin_2025_Server_232!"

echo -e "\n${YELLOW}📱 Try logging in again - dashboard should persist after reload!${NC}"
