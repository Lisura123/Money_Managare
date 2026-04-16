import axios from 'axios'

const TOKEN_KEY = 'mm_staff_token'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api',
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
  timeout: 15000,
})

// Request interceptor — attach Bearer token to every request
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem(TOKEN_KEY)
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => Promise.reject(error),
)

// Response interceptor — handle 401 globally
api.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status

    if (status === 401) {
      // Token expired or invalid — clear storage and redirect
      localStorage.removeItem(TOKEN_KEY)
      localStorage.removeItem('mm_staff_user')

      // Dispatch a custom event so AuthContext can react
      window.dispatchEvent(new CustomEvent('mm:session-expired'))
    }

    return Promise.reject(error)
  },
)

export { TOKEN_KEY }
export default api
