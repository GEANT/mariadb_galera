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
  $galera_ips_v4_string    = $mariadb_galera::params::galera_ips_v4_string,
  $galera_ips_v4           = $mariadb_galera::params::galera_ips_v4,
  $my_ip                   = $mariadb_galera::params::my_ip,
  $galera_ips_v4_separated = $mariadb_galera::params::galera_ips_v4_separated
) {

  file {
    '/etc/default/clustercheck':
      source => "puppet:///modules/${module_name}/etc_default_clustercheck";
    '/usr/bin/clustercheck':
      mode   => '0755',
      source => "puppet:///modules/${module_name}/usr_bin_clustercheck";
    '/etc/mysql/mariadb.conf.d/50-server.cnf':
      notify  => Service['mariadb'],
      require => Package['mariadb-server'],
      content => epp("${module_name}/50-server.cnf.epp", {
        innodb_buffer_pool_size_percent => $innodb_buffer_pool_size_percent,
        innodb_flush_method             => $innodb_flush_method,
        innodb_log_file_size            => $innodb_log_file_size,
        max_connections                 => $max_connections
      });
    '/etc/mysql/mariadb.conf.d/60-galera.cnf':
      notify  => Service['mariadb'],
      require => Package['mariadb-server'],
      content => epp("${module_name}/60-galera.cnf.epp", {
        galera_ips_v4_string => $galera_ips_v4_string,
        my_ip                => $my_ip
      });
    '/etc/mysql/mariadb.cnf':
      notify  => Service['mariadb'],
      require => Package['mariadb-server'],
      source  => "puppet:///modules/${module_name}/mariadb.cnf";
  }

}
