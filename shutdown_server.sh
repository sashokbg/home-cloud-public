#!/bin/sh

docker-compose -f docker-compose.yml -f docker-compose.nginx.yml -f docker-compose.certificate.yml down
