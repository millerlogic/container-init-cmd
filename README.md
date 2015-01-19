# container-init-cmd
An init for containers that can run a preset service

If you ever wanted to run an init but don't want to re design your docker files, this script could be useful.

All you need to add to your dockerfile is
```
ADD init-cmd.sh /sbin/init-cmd
ENTRYPOINT ["/sbin/init-cmd"]
```

and your normal CMD line can still be used, it will be added as an init.d script in the container.

The docker USER must be root; if you want another user, you can use ENV CMD_USER=
