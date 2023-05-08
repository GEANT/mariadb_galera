# == Class: mariadb_galera::files
#
#
class mariadb_galera::files (
  $innodb_buffer_pool_size_percent,
  $innodb_flush_method,
  $innodb_log_file_size,
  $max_connections,
  $custom_server_cnf_parameters,
  $thread_cache_size,
  $galera_servers_pattern,
  $my_ip = $mariadb_galera::params::my_ip,
) {
  $galera_server_hash = puppetdb_query("inventory[facts.ipaddress, facts.ipaddress6] {facts.hostname ~ '${galera_servers_pattern}' and facts.agent_specified_environment = '${::environment}'}")

  $galera_ips_v6 = sort($galera_server_hash.map | $k, $v | { $v['facts.ipaddress6'] })
  $galera_ips_v4 = sort($galera_server_hash.map | $k, $v | { $v['facts.ipaddress'] })
  $galera_ips_v4_string = join($galera_ips_v4, ',')
  $_galera_ips_v4_space_separated = join($galera_ips_v4, ':3306 ')
  $galera_ips_v4_separated = "${_galera_ips_v4_space_separated}:3307"

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
      content => epp(
        "${module_name}/50-server.cnf.epp", {
          innodb_buffer_pool_size_percent => $innodb_buffer_pool_size_percent,
          innodb_flush_method             => $innodb_flush_method,
          innodb_log_file_size            => $innodb_log_file_size,
          max_connections                 => $max_connections
        }
      );
    '/etc/mysql/mariadb.conf.d/60-galera.cnf':
      notify  => Service['mariadb'],
      content => epp(
        "${module_name}/60-galera.cnf.epp", {
          galera_ips_v4_string => $galera_ips_v4_string,
          my_ip                => $my_ip
        }
      );
    '/etc/mysql/mariadb.cnf':
      notify => Service['mariadb'],
      source => "puppet:///modules/${module_name}/mariadb.cnf";
    '/usr/local/bin/mysqltuner.pl':
      mode   => '0755',
      source => 'puppet:///modules/depot/mysql/mysqltuner.pl';
  }
}
