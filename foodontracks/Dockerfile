# Use official Node.js image
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy project files and build the app
COPY . .
RUN npm run build

# Expose the app port
EXPOSE 3000

# Start the app
CMD ["npm", "run", "start"]

# Create and setup the database
RUN apk add --no-cache postgresql-client \
    && psql -h localhost -U postgres -c "CREATE DATABASE foodontracks;" \
    && psql -h localhost -U postgres -d foodontracks -f /app/db/schema.sql \
    && psql -h localhost -U postgres -d foodontracks -c "\l" \
    && rm -f /app/db/schema.sql \
    && echo "Database setup completed." \
    && psql -h localhost -U postgres -d foodontracks -c "\q"
