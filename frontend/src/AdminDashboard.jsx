import React from 'react';
import Admin from './Admin';

function AdminDashboard({ token, onLogout }) {
  // Token validation is now handled in App.jsx
  // This component only renders when token is valid
  
  if (!token) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        backgroundColor: '#f8f9fa'
      }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: '24px', marginBottom: '20px' }}>⚠️</div>
          <div>Access denied. No valid token.</div>
        </div>
      </div>
    );
  }

  return <Admin token={token} onLogout={onLogout} />;
}

export default AdminDashboard;
