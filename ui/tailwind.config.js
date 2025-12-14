/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          blue: '#3B82F6',
          teal: '#14B8A6',
        },
        dark: {
          bg: '#0F172A',
          card: '#1E293B',
          border: '#334155',
        }
      }
    },
  },
  plugins: [],
}
