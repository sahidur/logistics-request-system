// Environment configuration
export const config = {
  API_URL: import.meta.env.VITE_API_URL || 'http://localhost:4000',
  APP_TITLE: import.meta.env.VITE_APP_TITLE || 'TikTok Learning Sharing Workshop',
  MAX_FILE_SIZE: parseInt(import.meta.env.VITE_MAX_FILE_SIZE) || 10485760,
  IS_DEV: import.meta.env.VITE_DEV_MODE === 'true' || import.meta.env.DEV,
  VERSION: import.meta.env.VITE_APP_VERSION || '1.0.0'
};

// API endpoints
export const API_ENDPOINTS = {
  REGISTER: `${config.API_URL}/api/register`,
  LOGIN: `${config.API_URL}/api/login`,
  REQUESTS: `${config.API_URL}/api/requests`,
  SUBMIT: `${config.API_URL}/api/requests`,
  EXPORT: `${config.API_URL}/api/export`,
  HEALTH: `${config.API_URL}/health`
};
