FROM nginx:alpine

RUN apk update && apk upgrade

COPY website /usr/share/nginx/html

EXPOSE 80