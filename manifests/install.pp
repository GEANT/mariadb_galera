# == Class: mariadb_galera::install
#
#
class mariadb_galera::install (
  $mariadb_packages = $mariadb_galera::params::mariadb_packages
) {

  class { 'mysql::client':
    package_manage  => false,
    bindings_enable => false
  }

  package { ['mariadb-client', 'mysql-server']:
    ensure  => present,
    require => [Exec['apt_update'], Apt::Source['mariadb-server']];
  }

}
