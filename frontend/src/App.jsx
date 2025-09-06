import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import './App.css';
import LogisticsForm from './LogisticsForm';
import AdminLogin from './AdminLogin';
import AdminDashboard from './AdminDashboard';

function App() {
  const [adminToken, setAdminToken] = useState(null);
  const [tokenChecked, setTokenChecked] = useState(false);

  // Check for existing token on app load
  useEffect(() => {
    const checkToken = () => {
      const storedToken = localStorage.getItem('adminToken') || sessionStorage.getItem('adminToken');
      console.log('🔍 Token check on app load:', storedToken ? 'Found' : 'Not found');
      
      if (storedToken) {
        setAdminToken(storedToken);
      }
      setTokenChecked(true);
    };

    checkToken();
  }, []);

  const handleAdminLogin = (token) => {
    console.log('✅ Admin login successful, storing token');
    setAdminToken(token);
    localStorage.setItem('adminToken', token);
    sessionStorage.setItem('adminToken', token);
  };

  const handleAdminLogout = () => {
    console.log('🚪 Admin logout, clearing all tokens');
    setAdminToken(null);
    localStorage.removeItem('adminToken');
    sessionStorage.removeItem('adminToken');
  };

  // Show loading until token check is complete
  if (!tokenChecked) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        backgroundColor: '#f8f9fa'
      }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: '32px', marginBottom: '16px' }}>🔄</div>
          <div style={{ fontSize: '18px', color: '#6c757d' }}>Loading...</div>
        </div>
      </div>
    );
  }

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
              adminToken ? (
                <AdminDashboard 
                  token={adminToken} 
                  onLogout={handleAdminLogout} 
                />
              ) : (
                <Navigate to="/admin" replace />
              )
            } 
          />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
