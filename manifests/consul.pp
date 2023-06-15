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
    address => $facts['ipaddress'],
    checks  => [
      {
        http     => 'http://localhost:9200',
        interval => '10s'
      },
    ],
    port    => 3306,
    tags    => [
      "${db_env}-traefik.enable=true",
      "${db_env}-traefik.tcp.routers.mariadb.rule=HostSNI(`*`)",
      "${db_env}-traefik.tcp.routers.mariadb.entrypoints=${db_env}-mariadb-galera",
      "${db_env}-traefik.tcp.routers.mariadb.service=${db_env}-mariadb-galera",
      "${db_env}-traefik.tcp.services.mariadb.loadbalancer.server.port=3306",
    ],
    require => Class['geant_consul::agent::consul'];
  }
}
