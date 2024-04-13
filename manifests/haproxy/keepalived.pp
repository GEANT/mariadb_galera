# == Class: mariadb_galera::haproxy::keepalived
#
#
# === Parameters
#
# [*vip_fqdn*]
#   FQDN of the VIP
#
# [*galera_other_ipv4s*]
#   An array of the IP addresses of the other nodes in the cluster.
#
# [*my_ipv4*]
#   The IP address of the current node. Defaults to $mariadb_galera::params::my_ipv4.
#
class mariadb_galera::haproxy::keepalived (
  Stdlib::Fqdn $vip_fqdn,
  Array[Stdlib::Ip::Address::Nosubnet] $galera_other_ipv4s,
  Stdlib::Ip::Address $my_ipv4 = $mariadb_galera::params::my_ipv4,
) {
  include "${facts['repo_prefix']}::keepalived"
  include geant_haproxy::keepalived::dummy_net

  $vip_ipv4 = dnsquery::a($vip_fqdn)
  $vip_ipv6 = dnsquery::aaaa($vip_fqdn)
  $subnet_v4 = $facts['networking']['interfaces']['bindings']['eth0']['netmask']
  $subnet_v6 = $facts['networking']['interfaces']['bindings6']['eth0']['netmask']
  $my_ipv4 = dnsquery::a($facts['networking']['fqdn'])

  case $facts['networking']['hostname'] {
    /01/: {
      $state = 'MASTER'
      $priority = 100
    }
    default: {
      $state = 'BACKUP'
      $priority = 99
    }
  }
  class { 'keepalived':
    require         => Class["${facts['repo_prefix']}::keepalived"],
    pkg_ensure      => 'latest',
    sysconf_options => '-D --snmp',
  }

  class { 'keepalived::global_defs':
    script_user            => 'root',
    enable_script_security => true;
  }

  keepalived::vrrp::script { 'check_haproxy':
    script   => '/usr/bin/killall -0 haproxy',
    weight   => 2,  # integer added/removed to/from priority
    rise     => 1,  # required number of OK
    fall     => 1,  # required number of KO
    interval => 2;
  }

  keepalived::vrrp::instance { 'HAProxy':
    interface                  => 'eth0',
    state                      => $state,
    virtual_router_id          => seeded_rand(255, "${module_name}${facts['agent_specified_environment']}") + 0,
    unicast_source_ip          => $my_ipv4,
    unicast_peers              => $galera_other_ipv4s,
    priority                   => $priority + 0,
    auth_type                  => 'PASS',
    auth_pass                  => seeded_rand_string(8, "${module_name}${facts['agent_specified_environment']}"),  # pass is truncated to 8
    virtual_ipaddress          => "${vip_ipv4}/${subnet_v4}",
    virtual_ipaddress_excluded => ["${vip_ipv6}/${subnet_v6} preferred_lft 0"],
    track_script               => 'check_haproxy',
    track_interface            => ['eth0'],
    require                    => Class['geant_haproxy::keepalived::dummy_net'];
  }
}
# vim:ts=2:sw=2
