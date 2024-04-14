# module for app mariadb_galera

## First time setup

### remove stale files

Only when you install it for the first time.

This procedure is not needed and should not be used in any subsequent bootstrap operation.

To bootstrap the first node you run the followings:

```bash
rm -f /var/lib/mysql/ibdata1 /var/lib/mysql/ib_logfile0
galera_new_cluster
```

in the other nodes:

```bash
rm -f /var/lib/mysql/ibdata1 /var/lib/mysql/ib_logfile0  # is this really needed?
systemctl start mysql
```

### Load balancer type

it's possible to use either `consul` or `haproxy`. They both have pros and cons.

## consul

it is way easier to setup, but the load balancing supports only `weight`, through the consul check, when the check emits a warning. _This is not implemented in this module_.

On the other side, it uses DNS intensively.

## haproxy

haproxy requires Keepalived and a VIP address. It's possible to use different load-balancing methods.

On the other side, HAProxy introduce a security problem: the client connects using the IP of the proxy, and you won't be able to limit the access based on source IP.

To circumvent this issue Percona/MariaDB introduced the `proxy_protocol_networks`.

Proxy Protocol Network is described at this URL [here](https://mariadb.com/kb/en/proxy-protocol-support/), but _it's not yet implemented in this module_.
