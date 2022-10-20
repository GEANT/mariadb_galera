# == Class: mariadb_galera::consul
#
#
class mariadb_galera::consul {

  include geant_consul::agent::consul

  consul::service { "${::environment}-mariadb-galera":
    address => $facts['ipaddress'],
    checks  => [
      {
        http     => 'http://localhost:9200',
        interval => '10s'
      }
    ],
    port    => 3600,
    require => Class['geant_consul::agent::consul'];
  }

}
