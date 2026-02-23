/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        background: '#0A0E21',
        surface: '#1A1F3D',
        card: '#141729',
        primary: '#00D4FF',
        secondary: '#00FF88',
        accent: '#9D4EDD',
        danger: '#FF3366',
      },
      boxShadow: {
        neon: '0 0 10px rgba(0, 212, 255, 0.5), 0 0 20px rgba(0, 212, 255, 0.3)',
        'neon-green': '0 0 10px rgba(0, 255, 136, 0.5), 0 0 20px rgba(0, 255, 136, 0.3)',
        'neon-purple': '0 0 10px rgba(157, 78, 221, 0.5), 0 0 20px rgba(157, 78, 221, 0.3)',
        'neon-danger': '0 0 10px rgba(255, 51, 102, 0.5)',
      },
    },
  },
  plugins: [],
}
