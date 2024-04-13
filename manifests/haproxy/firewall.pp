# == Class: mariadb_galera::haproxy::firewall
#
#
# === Parameters
#
# [*galera_other_ipv4s*]
#   An array of the IP addresses of the other nodes in the cluster.
#
class mariadb_galera::haproxy::firewall (
  Array[Stdlib::Ip::Address::Nosubnet] $galera_other_ipv4s
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
