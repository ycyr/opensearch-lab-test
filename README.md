# opensearch-lab-test

Based on https://github.com/stefanprodan/dockprom


Clone this repository on your Docker host, cd into directory and run the following command:

```bash
git clone https://github.com/ycyr/opensearch-lab-test
cd opensearch-lab-test

cd opensearch
openssl genrsa -out key.pem 2048 
openssl rsa -in key.pem -outform PEM -pubout -out public.pem 
chmod 644 *.pem

sed -i  's/KEY_REPLACE_ME/YOUR_AWS_S3_ACCESS_KEY/' Dockerfile
sed -i  's/SECRET_REPLACE_ME/YOUR_AWS_S3_SECRET_KEY/' Dockerfile

cd ..
ADMIN_USER=admin ADMIN_PASSWORD=admin ADMIN_PASSWORD_HASH=JDJhJDE0JE91S1FrN0Z0VEsyWmhrQVpON1VzdHVLSDkyWHdsN0xNbEZYdnNIZm1pb2d1blg4Y09mL0ZP docker-compose up -d
```
Creating fake logs send then in Opensearch

```
docker run -it  --log-driver fluentd --net host  --log-opt fluentd-address=127.0.0.1:24224 --log-opt tag=es --rm mingrammer/flog -b 104857600
```

**Caddy v2 does not accept plaintext passwords. It MUST be provided as a hash value. The above password hash corresponds to ADMIN_PASSWORD 'admin'. To know how to generate hash password, refer [Updating Caddy to v2](#Updating-Caddy-to-v2)**

Prerequisites:

* Docker Engine >= 1.13
* Docker Compose >= 1.11

## Updating Caddy to v2

Perform a `docker run --rm caddy caddy hash-password --plaintext 'ADMIN_PASSWORD'` in order to generate a hash for your new password.
ENSURE that you replace `ADMIN_PASSWORD` with new plain text password and `ADMIN_PASSWORD_HASH` with the hashed password references in [docker-compose.yml](./docker-compose.yml) for the caddy container.

Containers:

* Opensearch and Opensearch Dashboard `http://<host-ip>:5601`
* Cerebro `http://<host-ip>:9000`
* Prometheus (metrics database) `http://<host-ip>:9090`
* Grafana (visualize metrics) `http://<host-ip>:3000`
* NodeExporter (host metrics collector)
* cAdvisor (containers metrics collector)
* Caddy (reverse proxy and basic auth provider for prometheus)

Cheatsheet for testing snaphost

```

#Snaphot S3 Repository with Encrypted Repository Plugin for OpenSearch https://github.com/aiven/encrypted-repository-opensearch

PUT _snapshot/enc
  {
    "type": "encrypted",
    "settings": {
      "storage_type": "s3",   
      "client": "default",
      "bucket": "",
      "base_path": "enc"
    }
  }


#Snaphot S3 Repository 

PUT _snapshot/noenc
{
  "type": "s3",
  "settings": {
      "client": "default",
      "bucket": "YOUR_BUCKET_NAME",
      "base_path": "noenc"
  }
}

GET _cat/indices

# Create snaphost with Encrypted Repository Plugin

PUT _snapshot/enc/test1
{
  "indices": "logstash-*",
  "ignore_unavailable": true,
  "include_global_state": false,
  "partial": false
}

GET _snapshot/enc/test1


# Create without Encrypted Repository Plugin
 
PUT _snapshot/noenc/test1
{
  "indices": "logstash-*",
  "ignore_unavailable": true,
  "include_global_state": false,
  "partial": false
}
 

GET _snapshot/noenc/test1

# Restoring snaphost from none encrypted repository

POST _snapshot/noenc/test1/_restore
{
  "indices": "logstash-*",
  "ignore_unavailable": true,
  "include_global_state": false,
  "include_aliases": false,
  "partial": false,
  "rename_pattern": "(.+)",
  "rename_replacement": "noenc-$1",
  "index_settings": {
    "index.blocks.read_only": false
  },
  "ignore_index_settings": [
    "index.refresh_interval"
  ]
}
 

 GET _cat/recovery/noenc-logstash-2022.07.06
 
# Restoring snaphost from encrypted repository

 POST _snapshot/enc/test1/_restore
{
  "indices": "logstash-*",
  "ignore_unavailable": true,
  "include_global_state": false,
  "include_aliases": false,
  "partial": false,
  "rename_pattern": "(.+)",
  "rename_replacement": "enc-$1",
  "index_settings": {
    "index.blocks.read_only": false
  },
  "ignore_index_settings": [
    "index.refresh_interval"
  ]
}
 
  GET _cat/recovery/enc-logstash-2022.07.06
```
