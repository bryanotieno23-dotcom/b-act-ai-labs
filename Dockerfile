# Start by building the frontend and backend separately in their own stages

# Stage 1: Build the React Vite frontend
FROM node:16 as frontend

WORKDIR /app

COPY frontend/package.json frontend/package-lock.json ./frontend/
RUN npm install --prefix ./frontend

COPY frontend ./frontend
RUN npm run build --prefix ./frontend

# Stage 2: Build the Express.js backend
FROM node:16 as backend

WORKDIR /app

COPY backend/package.json backend/package-lock.json ./backend/
RUN npm install --prefix ./backend

COPY backend ./backend

# Copy the built frontend to the backend
COPY --from=frontend /app/frontend/dist ./backend/dist

# Start the backend server
CMD ["node", "./backend/index.js"]