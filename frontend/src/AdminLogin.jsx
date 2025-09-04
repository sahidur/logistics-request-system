import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import './AdminLogin.css';
import { API_ENDPOINTS } from './config';

function AdminLogin({ onLogin }) {
  const [adminLogin, setAdminLogin] = useState({ email: '', password: '' });
  const [adminError, setAdminError] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    setAdminError('');
    
    try {
      const res = await fetch(API_ENDPOINTS.LOGIN, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(adminLogin),
      });
      
      if (!res.ok) throw new Error('Invalid credentials');
      
      const data = await res.json();
      onLogin(data.token);
      navigate('/admin/dashboard');
    } catch (e) {
      setAdminError(e.message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="admin-login-bg">
      <div className="admin-login-container">
        <form className="admin-login-form" onSubmit={handleLogin}>
          <div className="admin-header">
            <h1>Admin Access</h1>
            <p>TikTok Learning Sharing Workshop</p>
            <div className="admin-divider"></div>
          </div>

          <div className="admin-form-group">
            <label htmlFor="email">Email Address</label>
            <input 
              id="email"
              className="admin-input"
              name="email" 
              value={adminLogin.email} 
              onChange={e => setAdminLogin(l => ({ ...l, email: e.target.value }))} 
              placeholder="admin@logistics.com" 
              type="email" 
              required 
            />
          </div>

          <div className="admin-form-group">
            <label htmlFor="password">Password</label>
            <input 
              id="password"
              className="admin-input"
              name="password" 
              value={adminLogin.password} 
              onChange={e => setAdminLogin(l => ({ ...l, password: e.target.value }))} 
              placeholder="Enter your password" 
              type="password" 
              required 
            />
          </div>

          {adminError && (
            <div className="admin-error">
              <span>⚠️</span>
              {adminError}
            </div>
          )}

          <button 
            type="submit" 
            className="admin-submit-btn" 
            disabled={submitting}
          >
            {submitting ? (
              <>
                <div className="loading-spinner"></div>
                Signing in...
              </>
            ) : (
              'Sign In'
            )}
          </button>

          <div className="admin-footer">
            <Link to="/" className="back-link">
              ← Back to Request Form
            </Link>
          </div>
        </form>
      </div>
    </div>
  );
}

export default AdminLogin;
