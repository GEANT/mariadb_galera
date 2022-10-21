# == Class: mariadb_galera
#
#
class mariadb_galera (
  Sensitive $root_password      = $mariadb_galera::params::root_password,

  # Innodb Options
  $innodb_buffer_pool_size      = $mariadb_galera::params::innodb_buffer_pool_size,
  $innodb_buffer_pool_instances = $mariadb_galera::params::innodb_buffer_pool_instances,
  $innodb_flush_method          = $mariadb_galera::params::innodb_flush_method,
  $innodb_log_file_size         = $mariadb_galera::params::innodb_log_file_size,
  $max_connections              = $mariadb_galera::params::max_connections,
  $thread_cache_size            = $mariadb_galera::params::thread_cache_size,
  $custom_server_cnf_parameters = $mariadb_galera::params::custom_server_cnf_parameters

) inherits mariadb_galera::params {

  include mariadb_galera::repo
  include mariadb_galera::install
  include mariadb_galera::services
  include mariadb_galera::consul

  class { 'mariadb_galera::files':
    innodb_buffer_pool_size      => $innodb_buffer_pool_size,
    innodb_buffer_pool_instances => $innodb_buffer_pool_instances,
    innodb_flush_method          => $innodb_flush_method,
    innodb_log_file_size         => $innodb_log_file_size,
    max_connections              => $max_connections,
    thread_cache_size            => $thread_cache_size
  }

  mariadb_galera::create::root_password { 'root':
    root_password => Sensitive($root_password),
    require       => Class['mariadb_galera::install'];
  }

}
