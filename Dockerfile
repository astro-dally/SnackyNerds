FROM node:18-alpine

WORKDIR /app

# Copy only server dependencies
COPY server/package*.json ./

RUN npm install

# Copy server code
COPY server/ .

EXPOSE 3000

CMD ["npm", "start"]
