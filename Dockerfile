FROM node:slim AS build

WORKDIR /app

COPY ./package*.json ./
RUN npm install

COPY . .

RUN npm run build

# Stage 2: Serve the application using nginx
FROM nginx:alpine as prod

# Copy built files
COPY --from=build /app/dist /usr/share/nginx/html
COPY ./nginx.conf /etc/
COPY ./nginx.conf /etc/nginx/nginx.conf.template

EXPOSE 80
