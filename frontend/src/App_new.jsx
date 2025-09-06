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
