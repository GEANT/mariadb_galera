# == Class: mariadb_galera::services
#
# This Class manages services
#
#
class mariadb_galera::services {

  xinetd::service { 'galerachk':
    server         => '/usr/bin/clustercheck',
    port           => '9200',
    user           => 'root',
    group          => 'root',
    groups         => 'yes',
    flags          => 'REUSE NOLIBWRAP',
    log_on_success => '',
    log_on_failure => 'HOST',
    require        => File[
      '/etc/default/clustercheck',
      '/usr/bin/clustercheck',
      #'/root/.my.cnf'
    ];
  }

  service { 'mariadb':
    ensure    => running,
    hasstatus => true,
    enable    => true,
    require   => Package['mariadb-server'];
  }

}
