# JD_Shell

docker compose
```yaml
version: "3"
services:
  jd:
    image: ffuqiangg/nodejd
    container_name: jd
    restart: always
    tty: true
    network_mode: host
    hostname: jd
    volumes:
      - ./config:/jd/config
      - ./log:/jd/log
      - ./raw:/jd/raw
      - ./scripts:/jd/scripts
    environment: 
      - url_scripts=
      - branch_scripts=
```
