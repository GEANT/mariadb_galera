# == Class: mariadb_galera::install
#
#
class mariadb_galera::install {
  class { 'mysql::client':
    package_name    => 'mariadb-client-core',
    package_ensure  => present,
    bindings_enable => false,
  }

  class { 'mysql::server':
    package_name       => 'mariadb-server',
    package_ensure     => present,
    service_name       => 'mariadb',
    managed_dirs       => false,
    manage_config_file => false,
    require            => [Exec['apt_update'], Apt::Source['mariadb']];
  }
}
