# == Class: mariadb_galera::files
#
#
class mariadb_galera::files (
  $galera_ips_v4_string    = $mariadb_galera::params::galera_ips_v4_string,
  $galera_ips_v4           = $mariadb_galera::params::galera_ips_v4,
  $my_ip                   = $mariadb_galera::params::my_ip,
  $galera_ips_v4_separated = $mariadb_galera::params::galera_ips_v4_separated,
  #$cloud_db_password       = $mariadb_galera::params::cloud_db_password
) {

  file {
    '/etc/mysql/mariadb.conf.d/60-galera.cnf':
      #notify  => Service['mariadb'],
      require => Package['mariadb-server'],
      content => epp("${module_name}/60-galera.cnf.epp", {
        galera_ips_string => $galera_ips_v4_string,
        my_ip             => $my_ip
      });
    '/etc/mysql/mariadb.cnf':
      #notify => Service['mariadb'],
      require => Package['mariadb-server'],
      source  => "puppet:///modules/${module_name}/mariadb.cnf";
    #'/root/.my.cnf':
    #  owner   => root,
    #  group   => root,
    #  mode    => '0640',
    #  content => "[client]\nuser=root\npassword=${cloud_db_password}\n"
  }

}
