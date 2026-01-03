/** next.config.js */
const path = require('path');

const nextConfig = {
  reactStrictMode: true,
  // Ensure Turbopack uses the project folder as root to resolve path aliases
  turbopack: {
    root: __dirname,
  },

  // HTTPS Redirect Configuration
  async redirects() {
    return [
      {
        source: '/:path*',
        has: [
          {
            type: 'header',
            key: 'x-forwarded-proto',
            value: 'http',
          },
        ],
        destination: 'https://:host/:path*',
        permanent: true,
      },
      {
        source: '/:path*',
        has: [
          {
            type: 'host',
            value: 'www.foodontracks.local',
          },
        ],
        destination: 'https://foodontracks.local/:path*',
        permanent: true,
      },
    ];
  },

  // Security Headers for HTTPS
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=31536000; includeSubDomains; preload',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'X-Frame-Options',
            value: 'SAMEORIGIN',
          },
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=()',
          },
        ],
      },
    ];
  },

  // Environment variable exposure
  env: {
    NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL || 'https://foodontracks.local',
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'https://api.foodontracks.local',
  },

  // Image optimization for HTTPS
  images: {
    domains: [
      'foodontracks.local',
      'www.foodontracks.local',
      'api.foodontracks.local',
    ],
  },
};

module.exports = nextConfig;
