// Environment configuration
export const config = {
  API_URL: import.meta.env.VITE_API_URL || 'http://localhost:4000/api',
  API_FALLBACK: import.meta.env.VITE_API_URL_FALLBACK || 'http://localhost:4000/api',
  APP_TITLE: import.meta.env.VITE_APP_TITLE || 'TikTok Learning Sharing Workshop',
  MAX_FILE_SIZE: parseInt(import.meta.env.VITE_MAX_FILE_SIZE) || 10485760,
  IS_DEV: import.meta.env.VITE_DEV_MODE === 'true' || import.meta.env.DEV,
  VERSION: import.meta.env.VITE_APP_VERSION || '1.0.0'
};

// Export API_BASE_URL for backward compatibility
export const API_BASE_URL = config.API_URL.replace('/api', '');

// API endpoints (API_URL already includes /api path)
export const API_ENDPOINTS = {
  REGISTER: `${config.API_URL}/register`,
  LOGIN: `${config.API_URL}/login`,
  REQUESTS: `${config.API_URL}/requests`,
  SUBMIT: `${config.API_URL}/requests`,
  EXPORT: `${config.API_URL}/export`,
  HEALTH: `${config.API_URL}/health`
};
