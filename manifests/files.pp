# == Class: mariadb_galera::files
#
# This class manages the files for the mariadb_galera module.
#
# === Parameters
#
# [*load_balancer*]
#   The load balancer to use. Defaults to 'haproxy'.
#
# [*innodb_buffer_pool_size_percent*]
#   The percentage of the total memory to use for the innodb_buffer_pool_size.
#   Defaults to 0.5.
#
# [*innodb_flush_method*]
#   The innodb_flush_method to use. Defaults to O_DIRECT.
#
# [*innodb_log_file_size*]
#   The innodb_log_file_size to use. Defaults to 512M.
#
# [*max_connections*]
#   The max_connections to use. Defaults to 1024.
#
# [*custom_server_cnf_parameters*]
#   A hash of custom parameters to add to the server.cnf file.
#
# [*thread_cache_size*]
#   The thread_cache_size to use. Defaults to 16.
#
# [*galera_ips_v4*]
#   An array of the IP addresses of nodes in the cluster.
#
# [*galera_other_hostnames*]
#   An array of the hostnames of the other nodes in the cluster.
#
# [*cluster_name*]
#   The name of the cluster. Defaults to "${caller_module_name} ${facts['agent_specified_environment']}".
#
# [*my_ipv4*]
#   The IP address of the current node. Defaults to $mariadb_galera::params::my_ipv4.
#
class mariadb_galera::files (
  Enum['consul', 'haproxy'] $load_balancer,
  Variant[Integer, String] $innodb_buffer_pool_size_percent,
  String $innodb_flush_method,
  String $innodb_log_file_size,
  Integer $max_connections,
  Hash $custom_server_cnf_parameters,
  Integer $thread_cache_size,
  String $cluster_name,
  Array[Stdlib::Ip::Address::Nosubnet] $galera_ips_v4,
  Array[String] $galera_other_hostnames,
  Stdlib::Ip::Address $my_ipv4 = $mariadb_galera::params::my_ipv4,
) {
  $galera_ips_v4_string = join($galera_ips_v4, ',')
  $mysql_port = $load_balancer ? {
    'consul'  => 3306,
    'haproxy' => 3307,
  }

  if $cluster_name.length > 30 {
    $shortened_cluster_name = cluster_name.split('')[1,30].join()
    echo { 'The cluster name must be 30 characters or less':
      message => "shortening the name to ${$shortened_cluster_name}",
    }
  } else {
    $shortened_cluster_name = $cluster_name
  }

  file {
    default:
      require => Package['mysql-server'];
    '/etc/default/clustercheck':
      source => "puppet:///modules/${module_name}/etc_default_clustercheck";
    '/usr/bin/clustercheck':
      mode   => '0755',
      source => "puppet:///modules/${module_name}/usr_bin_clustercheck";
    '/etc/mysql/mariadb.conf.d/50-server.cnf':
      notify  => Service['mariadb'],
      content => epp("${module_name}/50-server.cnf.epp",
        {
          innodb_buffer_pool_size_percent => $innodb_buffer_pool_size_percent,
          innodb_flush_method             => $innodb_flush_method,
          innodb_log_file_size            => $innodb_log_file_size,
          max_connections                 => $max_connections,
          custom_server_cnf_parameters    => $custom_server_cnf_parameters,
          thread_cache_size               => $thread_cache_size,
          galera_other_hostnames          => $galera_other_hostnames.join(','),
        }
      );
    '/etc/mysql/mariadb.conf.d/60-galera.cnf':
      notify  => Service['mariadb'],
      content => epp("${module_name}/60-galera.cnf.epp",
        {
          galera_ips_v4_string => $galera_ips_v4_string,
          my_ipv4              => $my_ipv4,
          cluster_name         => $cluster_name,
        }
      );
    '/etc/mysql/mariadb.cnf':
      notify => Service['mariadb'],
      content => epp("${module_name}/mariadb.cnf.epp", { mysql_port => $mysql_port });
    '/usr/local/bin/mysqltuner.pl':
      mode   => '0755',
      source => 'puppet:///modules/depot/mysql/mysqltuner.pl';
  }
}
