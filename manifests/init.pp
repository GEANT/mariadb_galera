# == Class: mariadb_galera
#
#
# This class installs and configures MariaDB Galera Cluster.
#
# === Parameters
#
# [*galera_servers_pattern*]
#   The pattern to use to find the galera servers on the PuppetDB.
#
# [*consul_enabled*]
#   Whether or not to use consul for discovery.
#
# [*root_password*]
#   The root password for the database.
#
# [*consul_service_name*]
#   The name of the consul service to use for discovery.
#
# [*repo_version*]
#   The version of the MariaDB repo to use.
#
# [*innodb_buffer_pool_size_percent*]
#   The percentage of the system memory to use for the innodb buffer pool.
#
# [*innodb_flush_method*]
#   The innodb flush method to use.
#
# [*innodb_log_file_size*]
#   The size of the innodb log file.
#
# [*max_connections*]
#   The maximum number of connections to allow.
#
# [*thread_cache_size*]
#   The number of threads to cache.
#
# [*custom_server_cnf_parameters*]
#   A hash of custom server cnf parameters to set.
#
class mariadb_galera (
  String $galera_servers_pattern,
  Boolean $consul_enabled            = $mariadb_galera::params::consul_enabled,
  Sensitive $root_password           = $mariadb_galera::params::root_password,
  String $consul_service_name        = $mariadb_galera::params::consul_service_name,
  Strint $repo_version               = $mariadb_galera::params::repo_version,

  # Innodb Options
  String $innodb_flush_method        = $mariadb_galera::params::innodb_flush_method,
  STring $innodb_log_file_size       = $mariadb_galera::params::innodb_log_file_size,
  Integer $max_connections           = $mariadb_galera::params::max_connections,
  Integer $thread_cache_size         = $mariadb_galera::params::thread_cache_size,
  Hash $custom_server_cnf_parameters = $mariadb_galera::params::custom_server_cnf_parameters,
  Variant[String, Integer] $innodb_buffer_pool_size_percent = $mariadb_galera::params::innodb_buffer_pool_size_percent
) inherits mariadb_galera::params {
  class { 'mariadb_galera::repo':
    repo_version => $repo_version,
  }

  include mariadb_galera::install
  include mariadb_galera::services
  include mariadb_galera::create::haproxy_user
  include mariadb_galera::create::backup_user

  $cluster_name = "${caller_module_name} ${facts['agent_specified_environment']}"

  if $consul_enabled {
    class { 'mariadb_galera::consul':
      consul_service_name => $consul_service_name,
    }
  }

  class { 'mariadb_galera::files':
    galera_servers_pattern          => $galera_servers_pattern,
    custom_server_cnf_parameters    => $custom_server_cnf_parameters,
    innodb_buffer_pool_size_percent => $innodb_buffer_pool_size_percent,
    innodb_flush_method             => $innodb_flush_method,
    innodb_log_file_size            => $innodb_log_file_size,
    max_connections                 => $max_connections,
    thread_cache_size               => $thread_cache_size,
    cluster_name                    => $cluster_name,
  }

  mariadb_galera::create::root_password { 'root':
    root_password => Sensitive($root_password),
    require       => Service['mariadb'];
  }
}
