import React, { useState } from 'react';
import { API_BASE_URL } from './config';

const LogisticsForm = () => {
  // State for basic information
  const [basic, setBasic] = useState({
    name: '',
    email: '',
    teamName: '',
    customTeam: ''
  });

  // State for workshop information
  const [workshopDate, setWorkshopDate] = useState('');
  const [estimatedAttendees, setEstimatedAttendees] = useState(0);

  // State for items
  const [items, setItems] = useState([{
    type: '',
    quantity: 1,
    description: '',
    priority: '',
    deadline: ''
  }]);

  // State for file uploads
  const [files, setFiles] = useState([]);

  // State for comments
  const [comments, setComments] = useState('');

  // UI State
  const [submitting, setSubmitting] = useState(false);
  const [submitStatus, setSubmitStatus] = useState({ message: '', type: '' });
  const [showModal, setShowModal] = useState(false);

  // Constants
  const TEAM_OPTIONS = [
    'Marketing', 'Engineering', 'Design', 'Product', 'Sales',
    'HR', 'Finance', 'Operations', 'Customer Success', 'Other'
  ];

  const ITEM_TYPES = [
    'Technology Equipment', 'Marketing Materials', 'Office Supplies',
    'Event Materials', 'Training Resources', 'Software Licenses',
    'Furniture', 'Catering', 'Venue Booking', 'Transportation', 'Other'
  ];

  const PRIORITIES = ['Low', 'Medium', 'High', 'Urgent'];

  // Validation
  const isFormValid = () => {
    if (!basic.name.trim()) return false;
    if (!basic.email.trim()) return false;
    if (!basic.teamName.trim()) return false;
    if (basic.teamName === 'Other' && !basic.customTeam.trim()) return false;

    for (const item of items) {
      if (!item.type.trim()) return false;
      if (!item.description.trim()) return false;
      if (!item.quantity || item.quantity <= 0) return false;
      if (!item.priority.trim()) return false;
    }

    return true;
  };

  // Handlers
  const updateBasic = (field, value) => {
    setBasic(prev => ({ ...prev, [field]: value }));
  };

  const updateItem = (index, field, value) => {
    setItems(prev => prev.map((item, i) => 
      i === index ? { ...item, [field]: value } : item
    ));
  };

  const addItem = () => {
    setItems(prev => [...prev, {
      type: '',
      quantity: 1,
      description: '',
      priority: '',
      deadline: ''
    }]);
  };

  const removeItem = (index) => {
    if (items.length > 1) {
      setItems(prev => prev.filter((_, i) => i !== index));
    }
  };

  const handleFileChange = (e) => {
    const selectedFiles = Array.from(e.target.files);
    const validFiles = selectedFiles.filter(file => file.size <= 10 * 1024 * 1024);
    setFiles(prev => [...prev, ...validFiles]);
  };

  const removeFile = (index) => {
    setFiles(prev => prev.filter((_, i) => i !== index));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!isFormValid()) {
      setSubmitStatus({ message: 'Please fill in all required fields', type: 'error' });
      return;
    }

    setSubmitting(true);
    setSubmitStatus({ message: '', type: '' });

    try {
      const formData = new FormData();
      
      // Add basic info
      formData.append('name', basic.name);
      formData.append('email', basic.email);
      formData.append('teamName', basic.teamName === 'Other' ? basic.customTeam : basic.teamName);
      
      // Add workshop info
      formData.append('workshopDate', workshopDate);
      formData.append('estimatedAttendees', estimatedAttendees);
      
      // Add items
      formData.append('items', JSON.stringify(items));
      
      // Add comments
      formData.append('comments', comments);
      
      // Add files
      files.forEach((file, index) => {
        formData.append(`file_${index}`, file);
      });

      const response = await fetch(`${API_BASE_URL}/api/logistics`, {
        method: 'POST',
        body: formData
      });

      if (response.ok) {
        const result = await response.json();
        setSubmitStatus({ 
          message: `Request submitted successfully! Request ID: ${result.id}`, 
          type: 'success' 
        });
        
        // Reset form
        setBasic({ name: '', email: '', teamName: '', customTeam: '' });
        setWorkshopDate('');
        setEstimatedAttendees(0);
        setItems([{ type: '', quantity: 1, description: '', priority: '', deadline: '' }]);
        setFiles([]);
        setComments('');
        
      } else {
        const errorData = await response.json();
        setSubmitStatus({ 
          message: errorData.message || 'Failed to submit request', 
          type: 'error' 
        });
      }
    } catch (error) {
      console.error('Error submitting form:', error);
      setSubmitStatus({ 
        message: 'Network error. Please try again.', 
        type: 'error' 
      });
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="form-bg">
      <form onSubmit={handleSubmit} className="logistics-form">
        <h2>🎯 TikTok Learning Sharing Workshop - Logistics Request</h2>
        
        {/* Basic Information */}
        <div className="basic-info">
          <div className="form-group">
            <label htmlFor="name">Full Name *</label>
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
            <label htmlFor="email">Email Address *</label>
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
          
          <div className="form-group">
            <label htmlFor="teamName">Team/Department *</label>
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
              <label htmlFor="customTeam">Specify Team *</label>
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

        {/* Workshop Information */}
        <div className="workshop-info">
          <h3>🏢 Workshop Information</h3>
          <div className="form-group">
            <label htmlFor="workshopDate">Preferred Workshop Date</label>
            <input
              type="date"
              id="workshopDate"
              className="form-input"
              value={workshopDate}
              onChange={(e) => setWorkshopDate(e.target.value)}
              min={new Date().toISOString().split('T')[0]}
              disabled={submitting}
            />
          </div>
          
          <div className="form-group">
            <label htmlFor="estimatedAttendees">Estimated Attendees</label>
            <input
              type="number"
              id="estimatedAttendees"
              className="form-input"
              value={estimatedAttendees}
              onChange={(e) => setEstimatedAttendees(parseInt(e.target.value) || 0)}
              min="1"
              max="1000"
              placeholder="Number of expected attendees"
              disabled={submitting}
            />
          </div>
        </div>

        {/* Items Section */}
        <div className="items-section">
          <h3>📦 Items Request</h3>
          {items.map((item, index) => (
            <div key={index} className="item-card">
              <div className="item-header">
                <h4>Item {index + 1}</h4>
                {items.length > 1 && (
                  <button
                    type="button"
                    onClick={() => removeItem(index)}
                    className="remove-btn"
                    disabled={submitting}
                  >
                    ❌
                  </button>
                )}
              </div>
              
              <div className="form-row">
                <div className="form-group">
                  <label>Item Type *</label>
                  <select
                    value={item.type}
                    onChange={(e) => updateItem(index, 'type', e.target.value)}
                    disabled={submitting}
                    required
                    className="form-select"
                  >
                    <option value="">Select item type</option>
                    {ITEM_TYPES.map((type) => (
                      <option key={type} value={type}>{type}</option>
                    ))}
                  </select>
                </div>
                
                <div className="form-group">
                  <label>Quantity *</label>
                  <input
                    type="number"
                    value={item.quantity}
                    onChange={(e) => updateItem(index, 'quantity', parseInt(e.target.value) || 0)}
                    min="1"
                    disabled={submitting}
                    required
                    className="form-input"
                  />
                </div>
              </div>
              
              <div className="form-group">
                <label>Description *</label>
                <textarea
                  value={item.description}
                  onChange={(e) => updateItem(index, 'description', e.target.value)}
                  placeholder="Detailed description of the item needed"
                  disabled={submitting}
                  required
                  rows="3"
                  className="form-textarea"
                />
              </div>
              
              <div className="form-row">
                <div className="form-group">
                  <label>Priority Level *</label>
                  <select
                    value={item.priority}
                    onChange={(e) => updateItem(index, 'priority', e.target.value)}
                    disabled={submitting}
                    required
                    className="form-select"
                  >
                    <option value="">Select priority</option>
                    {PRIORITIES.map((priority) => (
                      <option key={priority} value={priority}>{priority}</option>
                    ))}
                  </select>
                </div>
                
                <div className="form-group">
                  <label>Deadline</label>
                  <input
                    type="date"
                    value={item.deadline}
                    onChange={(e) => updateItem(index, 'deadline', e.target.value)}
                    min={new Date().toISOString().split('T')[0]}
                    disabled={submitting}
                    className="form-input"
                  />
                </div>
              </div>
            </div>
          ))}
          
          <button
            type="button"
            onClick={addItem}
            className="add-item-btn"
            disabled={submitting}
          >
            ➕ Add Another Item
          </button>
        </div>

        {/* File Upload */}
        <div className="upload-section">
          <h3>📎 File Upload</h3>
          <div className="form-group">
            <label htmlFor="files">Supporting Documents</label>
            <input
              type="file"
              id="files"
              multiple
              onChange={handleFileChange}
              disabled={submitting}
              className="file-input"
              accept=".pdf,.doc,.docx,.xls,.xlsx,.jpg,.jpeg,.png"
            />
            <small>Supported formats: PDF, DOC, DOCX, XLS, XLSX, JPG, PNG (Max 10MB each)</small>
          </div>
          
          {files.length > 0 && (
            <div className="file-list">
              <h4>Selected Files:</h4>
              {files.map((file, index) => (
                <div key={index} className="file-item">
                  <span>{file.name} ({(file.size / 1024 / 1024).toFixed(2)} MB)</span>
                  <button
                    type="button"
                    onClick={() => removeFile(index)}
                    disabled={submitting}
                    className="remove-file-btn"
                  >
                    ❌
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Additional Comments */}
        <div className="comments-section">
          <div className="form-group">
            <label htmlFor="comments">Additional Comments</label>
            <textarea
              id="comments"
              value={comments}
              onChange={(e) => setComments(e.target.value)}
              placeholder="Any additional information or special requirements..."
              disabled={submitting}
              rows="4"
              className="form-textarea"
            />
          </div>
        </div>

        {/* Submit Button */}
        <button
          type="submit"
          disabled={submitting || !isFormValid()}
          className={`submit-btn ${!isFormValid() ? 'disabled' : ''}`}
        >
          {submitting ? '🔄 Submitting...' : '🚀 Submit Request'}
        </button>

        {/* Success/Error Messages */}
        {submitStatus.message && (
          <div className={`status-message ${submitStatus.type}`}>
            {submitStatus.message}
          </div>
        )}
      </form>

      {/* Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>📋 Request Status</h3>
              <button className="modal-close-btn" onClick={() => setShowModal(false)}>
                ✖️
              </button>
            </div>
            <div className="modal-body">
              <p className="modal-message">{submitStatus.message}</p>
            </div>
            <div className="modal-footer">
              <button className="modal-btn" onClick={() => setShowModal(false)}>
                OK
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default LogisticsForm;
