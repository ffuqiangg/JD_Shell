```yaml
version: '3.7'
services:
  jd_scripts:
    container_name: jd
    image: ffuqiangg/nodejd
    network_mode: "host"
    restart: always
    volumes:
      - ./config:/jd/config
      - ./raw:/jd/raw
      - ./scripts:/jd/scripts
      - ./log:/jd/log
```
