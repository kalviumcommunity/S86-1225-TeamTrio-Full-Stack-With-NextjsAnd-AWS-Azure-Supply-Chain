/** next.config.js */
const nextConfig = {
  reactStrictMode: true,
  // swcMinify is now default in Next.js 16 and deprecated as config option
  
  // HTTPS Redirect Configuration
  async redirects() {
    return [
      // Force HTTPS redirect for all HTTP requests in production
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
      // Redirect www to non-www (optional, configure based on your domain strategy)
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
          // HTTPS Security Headers
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
      // Add your S3 bucket if using AWS
      // 'your-bucket.s3.amazonaws.com',
    ],
  },
};

module.exports = nextConfig;
