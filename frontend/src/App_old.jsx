
import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import './App.css';
import LogisticsForm from './LogisticsForm';
import AdminLogin from './AdminLogin';
import AdminDashboard from './AdminDashboard';

const TEAM_OPTIONS = [
  'Event Lead',
  'Session Plan',
  'Accommodation and Food',
  'Finance',
  'Transportation',
  'Team Building Activities',
  'Cultural Night',
  'Invitation and Logistics',
  'Photography',
  'MC (Master of Ceremonies)',
  'Other',
];

function LogisticsForm() {
  const [basic, setBasic] = useState({ name: '', email: '', teamName: '', customTeam: '' });
  const [items, setItems] = useState([
    { name: '', description: '', quantity: '', price: '', sampleFile: null, source: '' },
  ]);
  const [submitting, setSubmitting] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [modalMessage, setModalMessage] = useState('');
  const [modalType, setModalType] = useState('success'); // 'success' or 'error'

  const handleBasicChange = (e) => {
    const { name, value } = e.target;
    setBasic((prev) => ({ ...prev, [name]: value }));
  };

  const handleItemChange = (idx, e) => {
    const { name, value, files } = e.target;
    setItems((prev) =>
      prev.map((item, i) =>
        i === idx ? { ...item, [name]: files ? files[0] : value } : item
      )
    );
  };

  const addItem = () => {
    setItems((prev) => [
      ...prev,
      { name: '', description: '', quantity: '', price: '', sampleFile: null, source: '' },
    ]);
  };

  const removeItem = (idx) => {
    setItems((prev) => prev.filter((_, i) => i !== idx));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    
    console.log('🔄 Starting form submission...');
    console.log('🌐 API URL:', API_ENDPOINTS.SUBMIT);
    
    const formData = new FormData();
    formData.append('name', basic.name);
    formData.append('email', basic.email);
    formData.append('teamName', basic.teamName === 'Other' ? basic.customTeam : basic.teamName);
    formData.append('items', JSON.stringify(items.map(({ sampleFile, ...rest }) => rest)));
    
    console.log('📤 Form data prepared:', {
      name: basic.name,
      email: basic.email,
      teamName: basic.teamName === 'Other' ? basic.customTeam : basic.teamName,
      itemsCount: items.length
    });
    
    items.forEach((item, index) => {
      if (item.sampleFile) {
        console.log(`📎 Adding file ${index + 1}:`, item.sampleFile.name);
        formData.append('files', item.sampleFile);
      }
    });
    
    try {
      console.log('🌐 Sending request to backend...');
      
      // Add timeout to prevent hanging
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 30000); // 30 second timeout
      
      const response = await fetch(API_ENDPOINTS.SUBMIT, {
        method: 'POST',
        body: formData,
        signal: controller.signal
      });
      
      clearTimeout(timeoutId);
      console.log('📨 Response received:', response.status, response.statusText);
      console.log('📨 Response headers:', response.headers);
      console.log('📨 Content-Type:', response.headers.get('content-type'));
      
      // Check content type before parsing
      const contentType = response.headers.get('content-type');
      let responseData;
      
      if (contentType && contentType.includes('application/json')) {
        responseData = await response.json();
      } else {
        // If not JSON, get as text to see what we're receiving
        const textResponse = await response.text();
        console.error('🚨 Non-JSON response received:', textResponse.substring(0, 200));
        throw new Error(`Server returned HTML instead of JSON. This usually means the API endpoint is not found or there's a server error. Response: ${textResponse.substring(0, 100)}...`);
      }
      
      if (!response.ok) {
        console.error('API Error:', responseData);
        throw new Error(responseData.error || 'Failed to submit request');
      }
      
      console.log('✅ Success:', responseData);
      setModalType('success');
      setModalMessage('Request submitted successfully! 🎉');
      setShowModal(true);
      setItems([{ name: '', description: '', quantity: '', price: '', sampleFile: null, source: '' }]);
      setBasic({ name: '', email: '', teamName: '', customTeam: '' });
    } catch (error) {
      console.error('💥 Submission error:', error);
      let errorMessage = 'Unknown error occurred';
      
      if (error.name === 'AbortError') {
        errorMessage = 'Request timed out. Please check your connection and try again.';
      } else if (error.message) {
        errorMessage = error.message;
      }
      
      setModalType('error');
      setModalMessage('Error submitting request: ' + errorMessage);
      setShowModal(true);
    }
    
    console.log('🏁 Form submission completed');
    setSubmitting(false);
  };

  return (
    <div className="form-bg">
      <form className="logistics-form" onSubmit={handleSubmit}>
        <h2>TikTok Learning Sharing Workshop – Logistics Request Form</h2>
        
        <div className="workshop-info">
          <p><strong>Dear Team,</strong></p>
          <p>To ensure smooth arrangements for the <strong>TikTok Learning Sharing Workshop (September 11, 2025)</strong>, please submit any logistics requirements using this form.</p>
          <div className="deadline-notice">
            📌 <strong>Deadline: September 7, 2025, at 5:00 PM sharp</strong>
          </div>
          <p className="warning-text">Requests submitted beyond this deadline will be considered but cannot be guaranteed due to procurement and finance constraints.</p>
          <p className="signature">Thank you for your cooperation!<br/>– <strong>Logistics Team</strong></p>
        </div>
        
        <div className="form-content">
          <div className="basic-info">
          <div className="form-group">
            <input 
              className="form-input"
              name="name" 
              value={basic.name} 
              onChange={handleBasicChange} 
              placeholder="Your Full Name" 
              required 
            />
          </div>
          <div className="form-group">
            <input 
              className="form-input"
              name="email" 
              value={basic.email} 
              onChange={handleBasicChange} 
              placeholder="Email Address" 
              type="email" 
              required 
            />
          </div>
          <div className="form-group">
            <select 
              className="form-select"
              name="teamName" 
              value={basic.teamName} 
              onChange={handleBasicChange} 
              required
            >
              <option value="">Select Your Team</option>
              {TEAM_OPTIONS.map((opt) => (
                <option key={opt} value={opt}>{opt}</option>
              ))}
            </select>
          </div>
          {basic.teamName === 'Other' && (
            <div className="form-group">
              <input 
                className="form-input"
                name="customTeam" 
                value={basic.customTeam} 
                onChange={handleBasicChange} 
                placeholder="Enter your team name" 
                required 
              />
            </div>
          )}
        </div>

        <div className="items-section">
          <div className="items-header">
            <h3 className="items-title">Request Items</h3>
          </div>
          
          <div className="items-container">
            {items.map((item, idx) => (
            <div className="item-card" key={idx}>
              {items.length > 1 && (
                <button 
                  type="button" 
                  onClick={() => removeItem(idx)} 
                  className="remove-item-btn"
                  aria-label="Remove item"
                >
                  ×
                </button>
              )}
              
              <div className="item-grid">
                <div className="form-group">
                  <input 
                    className="form-input"
                    name="name" 
                    value={item.name} 
                    onChange={(e) => handleItemChange(idx, e)} 
                    placeholder="Your Item Name" 
                    required 
                  />
                </div>
                
                <div className="form-group">
                  <input 
                    className="form-input"
                    name="description" 
                    value={item.description} 
                    onChange={(e) => handleItemChange(idx, e)} 
                    placeholder="Item Description" 
                    required 
                  />
                </div>
                
                <div className="form-group">
                  <input 
                    className="form-input"
                    name="quantity" 
                    type="number" 
                    min="1" 
                    value={item.quantity} 
                    onChange={(e) => handleItemChange(idx, e)} 
                    placeholder="Enter quantity (e.g., 5)" 
                    required 
                  />
                </div>
                
                <div className="form-group">
                  <div className="price-input-wrapper">
                    <span className="bdt-icon">৳</span>
                    <input 
                      className="form-input price-input"
                      name="price" 
                      type="number" 
                      min="0" 
                      step="0.01"
                      value={item.price} 
                      onChange={(e) => handleItemChange(idx, e)} 
                      placeholder="Item Price (BDT)" 
                      required 
                    />
                  </div>
                </div>
                
                <div className="form-group">
                  <input 
                    className="form-input"
                    name="source" 
                    value={item.source} 
                    onChange={(e) => handleItemChange(idx, e)} 
                    placeholder="Source Location" 
                    required 
                  />
                </div>
                
                <div className="form-group file-input-wrapper">
                  <input 
                    className="file-input"
                    id={`file-${idx}`}
                    name="sampleFile" 
                    type="file" 
                    onChange={(e) => handleItemChange(idx, e)}
                  />
                  <label htmlFor={`file-${idx}`} className="file-input-label">
                    📎 {item.sampleFile ? item.sampleFile.name : 'Attach Sample'}
                  </label>
                </div>
              </div>
            </div>
          ))}
          </div>
          
          <div className="add-item-section">
            <button type="button" onClick={addItem} className="add-item-btn">
              <span>+</span> Add Another Item
            </button>
          </div>
        </div>
        </div>

        <button type="submit" className="submit-btn" disabled={submitting}>
          {submitting ? 'Submitting Request...' : 'Submit Request'}
        </button>
        
        {/* Subtle admin access link */}
        <div className="form-footer">
          <Link to="/admin" className="admin-access-link">Admin Access</Link>
        </div>
      </form>
      
      {/* Success/Error Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className={`modal-icon ${modalType}`}>
              {modalType === 'success' ? (
                <div className="checkmark">
                  <div className="checkmark-circle"></div>
                  <div className="checkmark-stem"></div>
                  <div className="checkmark-kick"></div>
                </div>
              ) : (
                <div className="error-mark">✕</div>
              )}
            </div>
            <div className="modal-message">{modalMessage}</div>
            <button 
              className="modal-close-btn" 
              onClick={() => setShowModal(false)}
            >
              Close
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

function App() {
  const [adminToken, setAdminToken] = useState('');

  const handleAdminLogin = (token) => {
    setAdminToken(token);
  };

  const handleAdminLogout = () => {
    setAdminToken('');
  };

  return (
    <Router basename="/">
      <Routes>
        <Route path="/" element={<LogisticsForm />} />
        <Route path="/admin" element={<AdminLogin onLogin={handleAdminLogin} />} />
        <Route path="/admin/dashboard" element={<AdminDashboard token={adminToken} onLogout={handleAdminLogout} />} />
      </Routes>
    </Router>
  );
}

export default App;
