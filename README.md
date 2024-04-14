# module for app mariadb_galera

## First time setup

### remove stale files

Only when you install it for the first time. This procedure should not be used in any subsequent bootstrap operation.

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

## Load balancer type

it's possible to use either `consul` or `haproxy`. They both have pros and cons.

### consul

it is way easier to conceive and to support, but the load balancing supports only `weight`, through the consul check, when the check emits a warning. _This is not yet implemented in this module_.

On the other side, it uses DNS intensively. It this really a problem? We have a DNS working in round-robin with [dnsdist](https://dnsdist.org/)

```puppet
class { 'mariadb_galera':
  load_balancer          => 'consul',
  galera_servers_pattern => 'academy0',
  cluster_name           => "academy_${facts['agent_specified_environment']}",
  consul_service_name    => "${facts['agent_specified_environment']}-academy-galera",
  repo_version           => $repo_version,
  before                 => Mariadb_galera::Create::User[$dbuser];
}
mariadb_galera::create::user { $dbuser:
  dbpass                 => Sensitive($dbpass),
  dbuser                 => $dbuser,
  galera_servers_pattern => 'academy0',
  privileges             => ['ALL'],
  table                  => "${dbname}.*",
  collate                => 'utf8mb4_unicode_ci',
  charset                => 'utf8mb4';
}
```

### haproxy

haproxy requires Keepalived and a VIP address. Withhg HAProxy is possible to tweak the load-balancing algorithm.

On the other side, HAProxy introduces a security problem: the client connects using the IP of the proxy, and you won't be able to limit the access based on source IP.

To circumvent this issue Percona/MariaDB introduced the `proxy_protocol_networks`.

Proxy Protocol Network is described at this URL [here](https://mariadb.com/kb/en/proxy-protocol-support/), but _it's not yet implemented in this module_.

```puppet
class { 'mariadb_galera':
  load_balancer          => 'haproxy',
  haproxy_vip_fqdn       => $dbhost,
  galera_servers_pattern => 'academy(-galera-vip|0)',
  cluster_name           => "academy_${facts['agent_specified_environment']}",
  repo_version           => $repo_version,
  before                 => Mariadb_galera::Create::User[$dbuser];
}
mariadb_galera::create::user { $dbuser:
  dbpass                 => Sensitive($dbpass),
  dbuser                 => $dbuser,
  galera_servers_pattern => 'academy0',
  privileges             => ['ALL'],
  table                  => "${dbname}.*",
  collate                => 'utf8mb4_unicode_ci',
  charset                => 'utf8mb4';
}
```
