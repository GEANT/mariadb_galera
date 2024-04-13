# == Class: mariadb_galera::keepalived::firewall
#
#
# === Parameters
#
# [*galera_other_ipv4s*]
#   An array of the IP addresses of the other nodes in the cluster.
#
class mariadb_galera::keepalived::firewall (
  Array[Stdlib::Ip::Address::Nodubnet] $galera_other_ipv4s
) {
  $galera_other_ipv4s.each |$ip| {
    firewall { "200 Allow VRRP inbound from ${ip}":
      action => accept,
      proto  => ['vrrp', 'igmp'],
      chain  => 'INPUT',
      source => $ip;
    }
  }
  firewall { '200 Allow VRRP inbound to multicast':
    proto       => ['vrrp', 'igmp'],
    chain       => 'INPUT',
    destination => '224.0.0.0/8';
  }
}
# vim:ts=2:sw=2
