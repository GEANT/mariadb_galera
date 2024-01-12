# == Class: mariadb_galera::create::backup_user
#
# This class installs and configures MariaDB Galera Cluster.
#
class mariadb_galera::create::backup_user {
  mysql_user { 'mariabackup@localhost':
    ensure        => present,
    #plugin  => 'unix_socket',
    password_hash => mysql_password('mariabackup'),
    require       => [Service['mariadb'], File['/root/.my.cnf']];
  }

  -> mysql_grant { 'mariabackup@localhost/*.*':
    ensure     => present,
    user       => 'mariabackup@localhost',
    table      => '*.*',
    privileges => ['BINLOG MONITOR', 'LOCK TABLES', 'PROCESS', 'RELOAD'];
    #privileges => ['USAGE', 'RELOAD', 'PROCESS', 'LOCK TABLES', 'REPLICATION CLIENT'];  # doesn't work
  }
}
