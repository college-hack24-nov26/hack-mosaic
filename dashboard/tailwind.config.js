/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        parchment: '#f4eee5',
        ink: {
          DEFAULT: '#141414',
          secondary: '#4e4d4c',
          metadata: '#737373',
          dark: '#F2EDE6'
        },
        brand: {
          primary: '#94e130', // Chartreuse
          hover: '#82c927'
        },
        alert: {
          critical: '#C62828', // Contagious red
          light: '#FFEBEE'
        },
        caution: {
          amber: '#F2994A', // Pending / Moderate risk
          light: '#FFF3E0'
        },
        vet: {
          accent: '#2F6FDE', // Authority / Vet role indicator badge
          light: '#E8F0FE'
        },
        surface: {
          card: '#ffffff',
          dark: '#1F1F1F'
        },
        border: {
          hairline: '#a1a1a1',
          dark: '#3A3A3A'
        }
      },
      fontFamily: {
        figtree: ['Figtree', 'sans-serif'],
        inter: ['Inter', 'sans-serif']
      },
      borderRadius: {
        'sm': '8px',
        'md': '12px',
        'lg': '20px',
        'pill': '9999px'
      }
    },
  },
  plugins: [],
}

