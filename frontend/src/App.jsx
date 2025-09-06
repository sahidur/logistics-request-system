import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import './App.css';
import LogisticsForm from './LogisticsForm';
import AdminLogin from './AdminLogin';
import AdminDashboard from './AdminDashboard';
import { API_ENDPOINTS } from './config';

function App() {
  const [adminToken, setAdminToken] = useState(null);
  const [tokenChecked, setTokenChecked] = useState(false);
  const [isValidating, setIsValidating] = useState(false);

  // Check for existing token on app load
  useEffect(() => {
    const checkToken = async () => {
      console.log('🚀 App.jsx: Starting token check...');
      const storedToken = localStorage.getItem('adminToken') || sessionStorage.getItem('adminToken');
      console.log('🔍 Token check on app load:', storedToken ? 'Found token' : 'No token found');
      
      if (storedToken) {
        console.log('🔄 Validating token with API...');
        setIsValidating(true);
        // Validate token by making a test API call
        try {
          console.log('📡 Making API request to:', API_ENDPOINTS.REQUESTS);
          const response = await fetch(API_ENDPOINTS.REQUESTS, {
            headers: {
              'Authorization': `Bearer ${storedToken}`
            }
          });
          
          console.log('📨 API Response status:', response.status);
          if (response.ok) {
            console.log('✅ Token is valid, setting admin token');
            setAdminToken(storedToken);
          } else {
            console.log('❌ Token is invalid (status:', response.status, '), clearing storage');
            localStorage.removeItem('adminToken');
            sessionStorage.removeItem('adminToken');
            setAdminToken(null);
          }
        } catch (error) {
          console.error('❌ Token validation failed with error:', error);
          console.error('❌ Error details:', error.message);
          // Don't clear token on network errors - could be temporary
          if (error.name === 'TypeError' && error.message.includes('fetch')) {
            console.log('🌐 Network error detected, keeping token for retry');
            setAdminToken(storedToken);
          } else {
            console.log('🗑️ Non-network error, clearing token');
            localStorage.removeItem('adminToken');
            sessionStorage.removeItem('adminToken');
            setAdminToken(null);
          }
        }
        setIsValidating(false);
      } else {
        console.log('ℹ️ No token found, proceeding without authentication');
      }
      console.log('✅ Token check completed');
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
  if (!tokenChecked || isValidating) {
    console.log('⏳ App.jsx: Showing loading state - tokenChecked:', tokenChecked, 'isValidating:', isValidating);
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
          <div style={{ fontSize: '18px', color: '#6c757d' }}>
            {isValidating ? 'Validating session...' : 'Loading...'}
          </div>
        </div>
      </div>
    );
  }

  console.log('🎯 App.jsx: Rendering main app - adminToken:', adminToken ? 'Present' : 'Not present');
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
