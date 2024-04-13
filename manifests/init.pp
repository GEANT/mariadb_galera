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
# [*cluster_name*]
#   The name of the cluster. Defaults to the module name and the environment.
#
# [*load_balancer*]
#   The load balancer to use. Defaults to 'haproxy'.
#
# [*haproxy_version*]
#   The version of haproxy to use. Defaults to latest.
#
# [*haproxy_repo_version*]
#   The version of the haproxy repo to use.
#
# [*interface*]
#   The network interface to use for the VIP. Defaults to 'eth0'.
#
# [*vip_fqdn*]
#   The FQDN of the VIP to use. Defaults to undef.
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
  String $cluster_name                     = "${caller_module_name} ${facts['agent_specified_environment']}",
  Enum['consul', 'haproxy'] $load_balancer = $mariadb_galera::params::load_balancer,
  String $haproxy_version                  = $mariadb_galera::params::haproxy_version,
  String $haproxy_repo_version             = $mariadb_galera::params::haproxy_repo_version,
  String $interface                        = $mariadb_galera::params::interface,
  Optional[Stdlib::Fqdn] $vip_fqdn         = $mariadb_galera::params::vip_fqdn,
  Sensitive $root_password                 = $mariadb_galera::params::root_password,
  String $consul_service_name              = $mariadb_galera::params::consul_service_name,
  String $repo_version                     = $mariadb_galera::params::repo_version,

  # Innodb Options
  String $innodb_flush_method              = $mariadb_galera::params::innodb_flush_method,
  String $innodb_log_file_size             = $mariadb_galera::params::innodb_log_file_size,
  Integer $max_connections                 = $mariadb_galera::params::max_connections,
  Integer $thread_cache_size               = $mariadb_galera::params::thread_cache_size,
  Hash $custom_server_cnf_parameters       = $mariadb_galera::params::custom_server_cnf_parameters,
  Variant[String, Integer] $innodb_buffer_pool_size_percent = $mariadb_galera::params::innodb_buffer_pool_size_percent,
) inherits mariadb_galera::params {
  class { 'mariadb_galera::repo': repo_version => $repo_version, }

  $galera_server_hash = puppetdb_query(
    "inventory[facts.networking.ip, facts.networking.ip6, facts.networking.hostname] \
    {facts.networking.hostname ~ '${galera_servers_pattern}' \
    and facts.agent_specified_environment = '${facts['agent_specified_environment']}'}"
  )
  $galera_hostnames = sort($galera_server_hash.map | $k, $v | { $v['facts.networking.hostname'] })
  $galera_other_hostnames = delete($galera_hostnames, $facts['networking']['hostname'])
  $galera_ips_v6 = sort($galera_server_hash.map | $k, $v | { $v['facts.networking.ip6'] })
  $galera_ips_v4 = sort($galera_server_hash.map | $k, $v | { $v['facts.networking.ip'] })
  $galera_other_ipv4s = delete($galera_ips_v4, dnsquery::aaaa($facts['networking']['fqdn'])[0])

  include mariadb_galera::install
  include mariadb_galera::services
  include mariadb_galera::create::haproxy_user
  include mariadb_galera::create::backup_user

  if $load_balancer == 'consul' {
    class { 'mariadb_galera::consul':
      consul_service_name => $consul_service_name,
    }
  } else {
    if $vip_fqdn =~ Undef {
      fail('You must specify a vip_fqdn when using haproxy as the load balancer')
    }
    class {
      'mariadb_galera::haproxy::repo':
        haproxy_repo_version => $haproxy_repo_version;
      'mariadb_galera::haproxy::haproxy':
        galera_hostnames => $galera_hostnames,
        vip_fqdn         => $vip_fqdn,
        haproxy_version  => $haproxy_version;
      'mariadb_galera::haproxy::keepalived':
        vip_fqdn           => $vip_fqdn,
        galera_other_ipv4s => $galera_other_ipv4s,
        interface          => $interface;
      'mariadb_galera::haproxy::firewall':
        galera_other_ipv4s => $galera_other_ipv4s;
    }
  }

  class { 'mariadb_galera::files':
    load_balancer                   => $load_balancer,
    galera_ips_v4                   => $galera_ips_v4,
    galera_other_hostnames          => $galera_other_hostnames,
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
