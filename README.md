# module for app mariadb_galera

## first time setup

### remove wrong files

in order to bootstrap for the first time:

```bash
rm -f /var/lib/mysql/ibdata1 /var/lib/mysql/ib_logfile0
galera_new_cluster
```

if needed, in the other nodes:

```bash
rm -f /var/lib/mysql/ibdata1 /var/lib/mysql/ib_logfile0
systemcrt start mysql
```

### add haproxy user

```sql
CREATE USER haproxy@'%';
GRANT PROCESS ON *.* TO 'haproxy'@'%';
FLUSH PRIVILEGES;
```
