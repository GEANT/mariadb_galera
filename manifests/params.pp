# == Class: mariadb_galera::params
#
#
class mariadb_galera::params {

  $server_hash = puppetdb_query("inventory[facts.ipaddress, facts.ipaddress6] {facts.hostname ~ 'mariadb-galera' and facts.agent_specified_environment = '${::environment}'}")
  $galera_ips_v6 = sort($server_hash.map | $k, $v | {$v['facts.ipaddress6'] })
  $galera_ips_v4 = sort($server_hash.map | $k, $v | {$v['facts.ipaddress'] })
  $galera_ips_v4_string = join($galera_ips_v4, ',')
  $_galera_ips_v4_space_separated = join($galera_ips_v4, ':3306 ')
  $galera_ips_v4_separated = "${_galera_ips_v4_space_separated}:3307"
  $my_ip = dns_a($facts['fqdn'])[0]

  $root_password = Sensitive(lookup('galera_root_password', Optional[String], 'first', 'root'))

  # == mysqld options
  #
  $innodb_buffer_pool_percent = '0.7'
  $innodb_buffer_pool_instances = floor(Float.new($facts['memorysize_mb']) * Float.new(0.7)/130)
  $innodb_flush_method = 'O_DIRECT'
  $innodb_log_file_size = '512M'
  $max_connections = 1024
  $thread_cache_size = 16
  $custom_server_cnf_parameters = {}

}
