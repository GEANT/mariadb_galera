# == Class: mariadb_galera
#
#
class mariadb_galera (
  String $galera_servers_pattern,
  Sensitive $root_password         = $mariadb_galera::params::root_password,

  # Innodb Options
  $innodb_buffer_pool_size_percent = $mariadb_galera::params::innodb_buffer_pool_size_percent,
  $innodb_flush_method             = $mariadb_galera::params::innodb_flush_method,
  $innodb_log_file_size            = $mariadb_galera::params::innodb_log_file_size,
  $max_connections                 = $mariadb_galera::params::max_connections,
  $thread_cache_size               = $mariadb_galera::params::thread_cache_size,
  $custom_server_cnf_parameters    = $mariadb_galera::params::custom_server_cnf_parameters

) inherits mariadb_galera::params {

  include mariadb_galera::repo
  include mariadb_galera::install
  include mariadb_galera::services
  include mariadb_galera::consul
  include mariadb_galera::create::haproxy_user

  class { 'mariadb_galera::files':
    galera_servers_pattern          => $galera_servers_pattern,
    custom_server_cnf_parameters    => $custom_server_cnf_parameters,
    innodb_buffer_pool_size_percent => $innodb_buffer_pool_size_percent,
    innodb_flush_method             => $innodb_flush_method,
    innodb_log_file_size            => $innodb_log_file_size,
    max_connections                 => $max_connections,
    thread_cache_size               => $thread_cache_size
  }

  mariadb_galera::create::root_password { 'root':
    root_password => Sensitive($root_password),
    require       => Service['mariadb'];
  }

}
