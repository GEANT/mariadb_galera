# == Class: mariadb_galera::install
#
#
class mariadb_galera::install (
  $mariadb_packages = $mariadb_galera::params::mariadb_packages
) {

  #class { 'mysql::client':
  #  package_manage  => false,
  #  bindings_enable => false
  #}
  #class { 'mysql::server':
  #  package_manage  => false,
  #}

  class { 'mysql::client':
    package_name    => 'mariadb-client',
    package_ensure  => present,
    bindings_enable => false,
  }
  class { 'mysql::server':
    package_name       => 'mariadb-server',
    package_ensure     => present,
    service_name       => 'mariadb',
    managed_dirs       => false,
    manage_config_file => false,
    require            => [Exec['apt_update'], Apt::Source['mariadb-server']];
  }

  #package { ['mariadb-client', 'mysql-server']:
  #  ensure  => present,
  #  require => [Exec['apt_update'], Apt::Source['mariadb-server']];
  #}

}
