# == Class: mariadb_galera::params
#
#
class mariadb_galera::params {

  $my_ip = dns_a($facts['fqdn'])[0]

  $root_password = Sensitive(lookup('galera_root_password', Optional[String], 'first', 'root'))

  # == mysqld options
  #
  $innodb_buffer_pool_size_percent = '0.7'
  $innodb_flush_method = 'O_DIRECT'
  $innodb_log_file_size = '512M'
  $max_connections = 1024
  $thread_cache_size = 16
  $custom_server_cnf_parameters = {}

}
