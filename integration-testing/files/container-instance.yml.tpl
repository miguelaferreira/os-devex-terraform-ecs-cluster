#cloud-config

runcmd:
  - echo "${environment}: OK" >> /tmp/user-data.txt
