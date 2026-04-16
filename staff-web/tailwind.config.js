/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'media',
  theme: {
    extend: {
      colors: {
        navy: {
          DEFAULT: '#1B2A4A',
          dark: '#0F1629',
          light: '#243561',
          50: '#f0f3f9',
          100: '#d9e0f0',
          900: '#0F1629',
        },
        teal: {
          DEFAULT: '#00BFA6',
          hover: '#00A896',
          light: '#E0F7F5',
        },
        accent: '#00BFA6',
        success: '#4CAF50',
        error: '#EF5363',
        warning: '#FFC107',
        background: '#F5F7FA',
        surface: '#FFFFFF',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        heading: ['Poppins', 'system-ui', 'sans-serif'],
      },
      borderRadius: {
        card: '12px',
      },
      boxShadow: {
        card: '0 2px 12px rgba(0,0,0,0.06)',
        'card-hover': '0 6px 24px rgba(0,0,0,0.10)',
        sidebar: '4px 0 16px rgba(0,0,0,0.08)',
      },
      animation: {
        'pulse-border': 'pulse-border 2s cubic-bezier(0.4,0,0.6,1) infinite',
        'fade-in': 'fadeIn 0.2s ease-out',
        'slide-in': 'slideIn 0.25s ease-out',
      },
      keyframes: {
        'pulse-border': {
          '0%, 100%': { boxShadow: '0 0 0 0 rgba(255,193,7,0.4)' },
          '50%': { boxShadow: '0 0 0 6px rgba(255,193,7,0)' },
        },
        fadeIn: {
          from: { opacity: '0', transform: 'translateY(4px)' },
          to: { opacity: '1', transform: 'translateY(0)' },
        },
        slideIn: {
          from: { transform: 'translateX(-100%)' },
          to: { transform: 'translateX(0)' },
        },
      },
    },
  },
  plugins: [],
}
