# == Class: mariadb_galera::backup
#
#
# This class installs and configures MariaDB Galera Cluster.
#
# === Parameters
#
# [*backup_password*]
#   Password for the backup user.
#
#
class mariadb_galera::backup (Sensitive $backup_password) inherits mariadb_galera::params {
  mysql_user { 'mariabackup@localhost':
    ensure        => present,
    password_hash => mysql_password($backup_password.unwrap),
    provider      => 'mysql';
  }

  -> mysql_grant { 'mariabackup@localhost/*.*':
    ensure     => present,
    user       => 'mariabackup@localhost',
    table      => '*.*',
    #privileges => ['USAGE', 'RELOAD', 'PROCESS', 'LOCK TABLES', 'REPLICATION CLIENT'];
    privileges => ['BINLOG MONITOR', 'LOCK TABLES', 'PROCESS', 'RELOAD'];
  }

  package { 'mariabackup':
    ensure => present,
  }
}
