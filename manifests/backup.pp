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

  mariadb_galera::create::grant { 'mariabackup@localhost':
    ensure     => present,
    dbuser     => 'mariabackup',
    table      => '*.*',
    privileges => ['GRANT', 'RELOAD', 'PROCESS', 'LOCK TABLES', 'REPLICATION CLIENT'],
    source     => 'localhost',
    require    => Mysql_user['mariabackup@localhost'];
  }
}
