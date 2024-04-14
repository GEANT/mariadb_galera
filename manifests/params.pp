# == Class: mariadb_galera::params
#
#
class mariadb_galera::params {
  $my_ipv4 = dnsquery::a($facts['networking']['fqdn'])[0]

  $load_balancer = 'consul'  # consul is kind of legacy, hence the default
  $consul_service_name = "${facts['agent_specified_environment']}-mariadb-galera"
  $repo_version = lookup('mariadb_repo_version', String, 'first', '10.11')
  $root_password = Sensitive(lookup('galera_root_password', String, 'first', 'root'))

  # == haproxy options
  #
  $haproxy_vip_fqdn = undef
  $haproxy_version = 'latest'
  $haproxy_repo_version = '2.8'
  $haproxy_check_method = 'xinetd'
  $interface = 'eth0'

  # == mysqld options
  #
  $innodb_buffer_pool_size_percent = '0.5'
  $innodb_flush_method = 'O_DIRECT'
  $innodb_log_file_size = '512M'
  $max_connections = 1024
  $thread_cache_size = 16
  $custom_server_cnf_parameters = {}
}
