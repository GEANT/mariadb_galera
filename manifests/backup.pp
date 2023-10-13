# == Class: mariadb_galera::backup
#
# This class installs and configures MariaDB Galera Cluster.
#
class mariadb_galera::backup {
  mysql_user { 'mariabackup@localhost':
    ensure => present,
    plugin => 'unix_socket',
  }

  -> mysql_grant { 'mariabackup@localhost/*.*':
    ensure     => present,
    user       => 'mariabackup@localhost',
    table      => '*.*',
    #privileges => ['USAGE', 'RELOAD', 'PROCESS', 'LOCK TABLES', 'REPLICATION CLIENT'];
    privileges => ['BINLOG MONITOR', 'LOCK TABLES', 'PROCESS', 'RELOAD'];
  }

  package { 'mariadb-backup':
    ensure => present,
  }
}
