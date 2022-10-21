# == Class: mariadb_galera
#
#
class mariadb_galera (
  Sensitive $root_password = $mariadb_galera::root_password
) inherits mariadb_galera::params {

  include mariadb_galera::repo
  include mariadb_galera::install
  include mariadb_galera::files
  include mariadb_galera::services
  include mariadb_galera::consul

  mariadb_galera::create::root_password { 'root':
    root_password => Sensitive($root_password),
    force_ipv6    => true,
    require       => Class['mariadb_galera::install'];
  }

}
