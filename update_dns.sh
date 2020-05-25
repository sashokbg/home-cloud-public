#!/bin/sh

domain_name=$1
account_id=$2
user_email=$3
global_token=$4
zoneId=''
dnsRecordId=''
ipv4=$(dig @resolver1.opendns.com ANY myip.opendns.com +short -4)
ipv6=$(dig @resolver1.opendns.com ANY myip.opendns.com +short -6)

context=/etc/dns_updater.conf

findZone () {
  zoneId=$(curl -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain_name&status=active&account.id=$account_id&page=1&per_page=1" \
     -H "X-Auth-Email: $user_email" \
     -H "X-Auth-Key: $global_token" \
     -H "Content-Type: application/json" | jq -r '.result[0].id')
}

findDnsRecord () {
  dnsRecordId=$(curl -X GET "https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records?type=A&name=$domain_name&page=1&per_page=1" \
     -H "X-Auth-Email: $user_email" \
     -H "X-Auth-Key: $global_token" \
     -H "Content-Type: application/json" | jq -r '.result[0].id')

  dnsRecordIdv6=$(curl -X GET "https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records?type=AAAA&name=$domain_name&page=1&per_page=1" \
     -H "X-Auth-Email: $user_email" \
     -H "X-Auth-Key: $global_token" \
     -H "Content-Type: application/json" | jq -r '.result[0].id')
}

updateDnsRecord () {
  if [ ! -f "/tmp/ipv4.dat" ]
  then
    previous_ipv4=0
  else
    previous_ipv4=`cat /tmp/ipv4.dat`
  fi

  if [ "$previous_ipv4" = "$ipv4" ]
  then
    echo "IPv4 not changed. Skipping."
    return
  fi

  curl -f -X PUT "https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records/$dnsRecordId" \
      -H "X-Auth-Email: $user_email" \
      -H "X-Auth-Key: $global_token" \
      -H "Content-Type: application/json" \
      --data "{\"type\":\"A\",\"name\":\"$domain_name\",\"content\":\"$ipv4\",\"ttl\":300,\"proxied\":false}"

  if [ $? -eq 0 ]
  then
    echo "Successfully updated IPv4 to $ipv4"
    echo $ipv4 > /tmp/ipv4.dat
  else
    echo "Error updating IPv4 !"
  fi

}

updateDnsRecordv6() {
  if [ ! -f "/tmp/ipv6.dat" ]
  then
    previous_ipv6=0
  else
    previous_ipv6=`cat /tmp/ipv6.dat`
  fi

  if [ "$previous_ipv6" = "$ipv6" ]
  then
    echo "IPv6 not changed. Skipping."
    return
  fi

  curl -f -X PUT "https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records/$dnsRecordIdv6" \
     -H "X-Auth-Email: $user_email" \
     -H "X-Auth-Key: $global_token" \
     -H "Content-Type: application/json" \
     --data "{\"type\":\"AAAA\",\"name\":\"$domain_name\",\"content\":\"$ipv6\",\"ttl\":300,\"proxied\":false}"

  if [ $? -eq 0 ]
  then
    echo "Successfully updated IPv6 to $ipv6"
    echo $ipv6 > /tmp/ipv6.dat
  else
    echo "Error updating IPv6 !"
  fi
}

findZone
findDnsRecord

echo "DNS Zone Id: $zoneId"
echo "DNS Record Id: $dnsRecordId"
echo "IPv4: $ipv4"
echo "IPv6: $ipv6"

updateDnsRecord
updateDnsRecordv6
