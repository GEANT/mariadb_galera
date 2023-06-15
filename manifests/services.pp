# == Class: mariadb_galera::services
#
# This Class manages services
#
#
# === Parameters
#
# [*mariadb_packages*]
#   Array of packages to install
#
class mariadb_galera::services (
  Array[String] $mariadb_packages = $mariadb_galera::params::mariadb_packages
) {
  xinetd::service { 'galerachk':
    server         => '/usr/bin/clustercheck',
    port           => '9200',
    user           => 'root',
    group          => 'root',
    groups         => 'yes',
    flags          => 'REUSE NOLIBWRAP',
    log_on_success => '',
    log_on_failure => 'HOST',
    require        => File[
      '/etc/default/clustercheck',
      '/usr/bin/clustercheck',
    ];
  }
}
