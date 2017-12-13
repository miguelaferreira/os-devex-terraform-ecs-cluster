#cloud-config

bootcmd:
  - echo "${environment}: OK" >> /tmp/user-data.txt
