#!/bin/sh

docker-compose -f docker-compose.yml -f docker-compose.certificate.yml up --build -d certbot

docker-compose -f docker-compose.yml -f docker-compose.certificate.yml exec certbot certbot --nginx -d $1 -m $2 --agree-tos --non-interactive

