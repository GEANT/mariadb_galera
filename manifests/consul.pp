# == Class: mariadb_galera::consul
#
#
# === Parameters
#
# [*consul_service_name*]
#   The name of the service to register in consul
#
class mariadb_galera::consul (String $consul_service_name) {
  $db_env = $facts['agent_specified_environment'] ? {
    'production' => 'prod',
    default => $facts['agent_specified_environment'],
  }

  include geant_consul::agent::consul

  consul::service { $consul_service_name:
    address => $facts['networking']['ip'],
    checks  => [
      {
        http     => 'http://localhost:9200',
        interval => '10s'
      },
    ],
    port    => 3306,
    tags    => ['tcp'],
    require => Class['geant_consul::agent::consul'];
  }
}
