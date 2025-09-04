import React from 'react';
import { useNavigate } from 'react-router-dom';
import Admin from './Admin';

function AdminDashboard({ token, onLogout }) {
  const navigate = useNavigate();

  const handleLogout = () => {
    onLogout();
    navigate('/admin');
  };

  if (!token) {
    navigate('/admin');
    return null;
  }

  return <Admin token={token} onLogout={handleLogout} />;
}

export default AdminDashboard;
