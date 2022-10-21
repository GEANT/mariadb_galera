# == Class: mariadb_galera::install
#
#
class mariadb_galera::install (
  $mariadb_packages = $mariadb_galera::params::mariadb_packages
) {

  #package { $mariadb_packages:
  #  ensure  => present,
  #  require => [Exec['apt_update'], Apt::Source['mariadb-server']];
  #}

  package { 'mysql_client':
    ensure  => present,
    name    => 'mariadb',
    require => [Exec['apt_update'], Apt::Source['mariadb-server']];
    #provider        => $mysql::client::package_provider,
    #source          => $mysql::client::package_source,
  }

  package { 'mysql-server':
    ensure  => present,
    name    => 'mariadb-server',
    require => [Exec['apt_update'], Apt::Source['mariadb-server']];
  }


}
