# == Class: mariadb_galera::install
#
#
class mariadb_galera::install {

  package { 'mariadb-server':
    ensure  => present,
    require => [Exec['apt_update'], Apt::Source['mariadb-server']];
  }

}
