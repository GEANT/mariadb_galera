# == Class: mariadb_galera::install
#
#
class mariadb_galera::install (
  $mariadb_packages = $mariadb_galera::params::mariadb_packages
) {

  package { $mariadb_packages:
    ensure  => present,
    require => [Exec['apt_update'], Apt::Source['mariadb-server']];
  }

}
