# Home Cloud with Next Cloud and Docker

This project aims at facilitating the running of a home cloud server
using docker and NextCloud by providing a number of docker services and some
bash scripts that run all the necessary tools.

## Config

Add nginx config in sites-enabled/{domain-name} and replace {domain} with your domain name.
```
upstream nextcloudupstream {
    server nextcloud:8080;
}

server {
  server_name {domain};
  
  location / {
    proxy_headers_hash_max_size 512;
    proxy_headers_hash_bucket_size 64;
    
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    
    add_header Front-End-Https on;

    proxy_pass http://nextcloud;
  }

}

server {
  if ($host = {domain}) {
    return 301 https://$host$request_uri;
  } # managed by Certbot


  listen 80 ;
  listen [::]:80 ;
  server_name {domain};
  return 404; # managed by Certbot 
}

```

Create a .env file with the following content

Change values accordingly..

```
HOME_CLOUD_PASS={secret pass}
HOME_CLOUD_DB_ROOT_PASS={very secert pass}
HOME_CLOUD_EMAIL={your email}
HOME_CLOUD_URL={your domain}

```

## Certificates
https://certbot.eff.org/lets-encrypt/ubuntubionic-nginx

Before obtainging or renewing a certificate you shuld stop you server.

Obtain a new certificate
```
obtain_certificate.sh {domain-name} {email}
```

Renew an existing certificate
```
renew_certificate.sh
```

## Server

Starting the server
```
run_server.sh
```

Stopping the server
```
shutdown_server.sh
```

## Add trusted domains to nextcloud
This is necessary so that you can connect yo your NextCloud instance by going through your domain.
By default it accepts only 'localhost'

```
docker exec --user www-data $(docker ps | awk '/nextcloud/ {print $1}') php occ config:system:set trusted_domains 4 --value https://{domain-name}.dev
```

## Connect to running docker container (for debugging)

docker exec -it $(docker ps | grep nginx | awk '{print $1}') /bin/sh

## Update DNS IP address
Whenever your IP address changes, run the following bash to update it (works only with cloudflare).

```
update_dns.sh {domain-name} {cloudflare-account-id} {cloudflare-user-email} {cloudflare-token}
```
