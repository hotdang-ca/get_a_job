FROM node:18-alpine

WORKDIR /web

COPY web ./

EXPOSE 80

RUN npm install -g serve

CMD [ "serve", "-l", "80" ]
