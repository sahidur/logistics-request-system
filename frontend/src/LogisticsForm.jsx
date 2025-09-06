import React, { useState } from 'react';
import { API_BASE_URL } from './config';

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

  const addItem = () => {
    if (items.length < 10) {
      setItems([...items, { name: '', description: '', quantity: '', price: '', sampleFile: null, source: '' }]);
    }
  };

  const removeItem = (index) => {
    if (items.length > 1) {
      setItems(items.filter((_, i) => i !== index));
    }
  };

  const updateItem = (index, field, value) => {
    const newItems = [...items];
    newItems[index][field] = value;
    setItems(newItems);
  };

  const updateBasic = (field, value) => {
    setBasic(prev => ({ ...prev, [field]: value }));
  };

  const validateForm = () => {
    if (!basic.name.trim()) return 'Name is required';
    if (!basic.email.trim()) return 'Email is required';
    if (!basic.teamName.trim()) return 'Team selection is required';
    if (basic.teamName === 'Other' && !basic.customTeam.trim()) return 'Please specify your team';
    
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      if (!item.name.trim()) return `Item ${i + 1}: Name is required`;
      if (!item.description.trim()) return `Item ${i + 1}: Description is required`;
      if (!item.quantity || item.quantity <= 0) return `Item ${i + 1}: Valid quantity is required`;
      if (!item.price || item.price <= 0) return `Item ${i + 1}: Valid price is required`;
      if (!item.source.trim()) return `Item ${i + 1}: Source is required`;
    }
    
    return null;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    const validationError = validateForm();
    if (validationError) {
      setModalMessage(validationError);
      setShowModal(true);
      return;
    }

    setSubmitting(true);
    
    try {
      const formData = new FormData();
      
      // User data
      const userData = {
        name: basic.name.trim(),
        email: basic.email.trim(),
        teamName: basic.teamName === 'Other' ? basic.customTeam.trim() : basic.teamName
      };
      
      formData.append('userData', JSON.stringify(userData));
      
      // Items data
      const itemsData = items.map(item => ({
        name: item.name.trim(),
        description: item.description.trim(),
        quantity: parseInt(item.quantity),
        price: parseFloat(item.price),
        source: item.source.trim()
      }));
      
      formData.append('items', JSON.stringify(itemsData));

      // File uploads
      items.forEach((item, index) => {
        if (item.sampleFile) {
          formData.append(`sampleFile_${index}`, item.sampleFile);
        }
      });

      const response = await fetch(`${API_BASE_URL}/api/logistics`, {
        method: 'POST',
        body: formData,
      });

      if (response.ok) {
        const result = await response.json();
        setModalMessage(`✅ Request submitted successfully! Your Request ID: ${result.id || 'TIK-' + Date.now()}`);
        setShowModal(true);
        
        // Reset form
        setBasic({ name: '', email: '', teamName: '', customTeam: '' });
        setItems([{ name: '', description: '', quantity: '', price: '', sampleFile: null, source: '' }]);
      } else {
        const errorData = await response.json();
        setModalMessage(`❌ Submission failed: ${errorData.message || 'Unknown error'}`);
        setShowModal(true);
      }
    } catch (error) {
      console.error('Submission error:', error);
      setModalMessage('❌ Network error. Please check your connection and try again.');
      setShowModal(true);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="form-bg">
      <div className="logistics-form">
        <h2>🎯 TikTok Learning Sharing Workshop – Logistics Request Form</h2>
        
        <div className="workshop-info">
          <p>📋 Logistics Request System</p>
          <div className="deadline-notice">
            <strong>Dear Team,</strong><br /><br />
            To ensure smooth arrangements for the TikTok Learning Sharing Workshop (September 11, 2025), please submit any logistics requirements using this form.<br />
            📌 <strong>Deadline: September 8, 2025, at 12:00 PM sharp</strong><br />
            Requests submitted beyond this deadline will be considered but cannot be guaranteed due to procurement and finance constraints.<br /><br />
            Thank you for your cooperation!<br />
            <span className="signature">– Logistics Team</span>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="form-content">
          {/* Basic Information */}
          <div className="form-section">
            <h3 className="section-title">👤 Basic Information</h3>
            <div className="basic-info">
              <div className="name-email-row">
                <div className="form-group">
                  <label htmlFor="name" className="form-label">Full Name *</label>
                  <input
                    type="text"
                    id="name"
                    className="form-input"
                    value={basic.name}
                    onChange={(e) => updateBasic('name', e.target.value)}
                    placeholder="Enter your full name"
                    disabled={submitting}
                    required
                  />
                </div>
                
                <div className="form-group">
                  <label htmlFor="email" className="form-label">Email Address *</label>
                  <input
                    type="email"
                    id="email"
                    className="form-input"
                    value={basic.email}
                    onChange={(e) => updateBasic('email', e.target.value)}
                    placeholder="Enter your email address"
                    disabled={submitting}
                    required
                  />
                </div>
              </div>
              
              <div className="form-group">
                <label htmlFor="teamName" className="form-label">Team/Department *</label>
                <select
                  id="teamName"
                  className="form-select"
                  value={basic.teamName}
                  onChange={(e) => updateBasic('teamName', e.target.value)}
                  disabled={submitting}
                  required
                >
                  <option value="">Select your team</option>
                  {TEAM_OPTIONS.map((team) => (
                    <option key={team} value={team}>{team}</option>
                  ))}
                </select>
              </div>
              
              {basic.teamName === 'Other' && (
                <div className="form-group">
                  <label htmlFor="customTeam" className="form-label">Specify Team *</label>
                  <input
                    type="text"
                    id="customTeam"
                    className="form-input"
                    value={basic.customTeam}
                    onChange={(e) => updateBasic('customTeam', e.target.value)}
                    placeholder="Enter your team name"
                    disabled={submitting}
                    required
                  />
                </div>
              )}
            </div>
          </div>

          {/* Items Section */}
          <div className="form-section">
            <div className="section-header">
              <h3 className="section-title">📦 Logistics Items Request</h3>
            </div>

            <div className="items-container">
              {items.map((item, index) => (
                <div key={index} className="item-card">
                  <div className="item-header">
                    <div className="item-number">Item {index + 1}</div>
                    {items.length > 1 && (
                      <button
                        type="button"
                        onClick={() => removeItem(index)}
                        className="remove-item-btn"
                        disabled={submitting}
                        title="Remove this item"
                      >
                        ✕
                      </button>
                    )}
                  </div>

                  <div className="item-grid">
                    <div className="form-group">
                      <label className="form-label">Item Name *</label>
                      <input
                        type="text"
                        className="form-input"
                        value={item.name}
                        onChange={(e) => updateItem(index, 'name', e.target.value)}
                        placeholder="Enter item name"
                        disabled={submitting}
                        required
                      />
                    </div>

                    <div className="form-group span-2">
                      <label className="form-label">Description *</label>
                      <textarea
                        className="form-textarea"
                        value={item.description}
                        onChange={(e) => updateItem(index, 'description', e.target.value)}
                        placeholder="Describe the item in detail"
                        rows="3"
                        disabled={submitting}
                        required
                      />
                    </div>

                    <div className="form-group">
                      <label className="form-label">Quantity *</label>
                      <input
                        type="number"
                        className="form-input"
                        value={item.quantity}
                        onChange={(e) => updateItem(index, 'quantity', e.target.value)}
                        placeholder="Enter quantity"
                        min="1"
                        disabled={submitting}
                        required
                      />
                    </div>

                    <div className="form-group">
                      <label className="form-label">Estimated Price (BDT) *</label>
                      <input
                        type="number"
                        className="form-input"
                        value={item.price}
                        onChange={(e) => updateItem(index, 'price', e.target.value)}
                        placeholder="Enter estimated price"
                        min="0"
                        step="0.01"
                        disabled={submitting}
                        required
                      />
                    </div>

                    <div className="form-group">
                      <label className="form-label">Source/Vendor *</label>
                      <input
                        type="text"
                        className="form-input"
                        value={item.source}
                        onChange={(e) => updateItem(index, 'source', e.target.value)}
                        placeholder="Where to buy this item"
                        disabled={submitting}
                        required
                      />
                    </div>

                    <div className="form-group">
                      <label className="form-label">Sample File (Optional)</label>
                      <input
                        type="file"
                        className="form-file-input"
                        onChange={(e) => updateItem(index, 'sampleFile', e.target.files[0])}
                        accept="image/*,.pdf,.doc,.docx"
                        disabled={submitting}
                      />
                      <small className="form-hint">Upload image, PDF, or document (Max 10MB)</small>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            <div className="add-item-section">
              <button
                type="button"
                onClick={addItem}
                className="add-item-btn"
                disabled={submitting || items.length >= 10}
              >
                ➕ Add Another Item
              </button>
            </div>
          </div>

          <div className="form-actions">
            <button type="submit" className="submit-btn" disabled={submitting}>
              {submitting ? (
                <>
                  <span className="loading-spinner"></span>
                  Submitting Request...
                </>
              ) : (
                <>
                  🚀 Submit Logistics Request
                </>
              )}
            </button>
          </div>
        </form>

        {/* Modal */}
        {showModal && (
          <div className="modal-overlay" onClick={() => setShowModal(false)}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h3>📋 Request Status</h3>
                <button 
                  className="modal-close-btn" 
                  onClick={() => setShowModal(false)}
                  aria-label="Close modal"
                >
                  ✖️
                </button>
              </div>
              <div className="modal-body">
                <p className="modal-message">{modalMessage}</p>
              </div>
              <div className="modal-footer">
                <button className="modal-btn" onClick={() => setShowModal(false)}>
                  Got it!
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default LogisticsForm;
