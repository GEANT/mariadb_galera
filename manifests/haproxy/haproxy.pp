# == Class: mariadb_galera::haproxy::haproxy
#
# This class installs and configures HAProxy for the MariaDB Galera cluster.
#
# === Parameters
#
# [*galera_hostnames*]
#   An array of hostnames of the Galera nodes.
#
# [*haproxy_vip_fqdn*]
#   The FQDN of the VIP.
#
# [*mysql_port*]
#   The port on which MySQL is listening.
#
# [*haproxy_version*]
#   The version of HAProxy to install.
#
# [*haproxy_check_method*]
#   The method to use for checking the health of the Galera nodes. Valid values are 'xinetd_check' and 'mysql_check'.
#
class mariadb_galera::haproxy::haproxy (
  Array[Stdlib::Fqdn] $galera_hostnames,
  Stdlib::Fqdn $haproxy_vip_fqdn,
  Stdlib::Port $mysql_port,
  String $haproxy_version,
  Enum['xinetd', 'mysql'] $haproxy_check_method,
) {
  $my_domain = $facts['networking']['domain']
  $check_port = $haproxy_check_method ? {
    'xinetd' => 'port 9200 ',
    'mysql'  => '',
  }
  $galera_backends_list = $galera_hostnames.map |$item| {
    { 'server' => "${item} ${dnsquery::a("${item}.${my_domain}")[0]}:${mysql_port} check ${check_port}weight 1" }
  }

  class { 'haproxy':
    package_ensure   => $haproxy_version,
    global_options   => {
      'log'                           => "/dev/log local0\n  log  /dev/log local1 notice",
      'chroot'                        => '/var/lib/haproxy',
      'maxconn'                       => '150000',
      'user'                          => 'haproxy',
      'group'                         => 'haproxy',
      'stats'                         => 'socket /var/run/haproxy.sock user root group sensu mode 660 level admin',
      'ssl-default-bind-ciphers'      => 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384', # lint:ignore:140chars
      'ssl-default-bind-ciphersuites' => 'TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256',
      'ssl-default-bind-options'      => 'ssl-min-ver TLSv1.2 no-tls-tickets',
      'tune.ssl.default-dh-param'     => '2048',
    },
    defaults_options => {
      'default-server' => 'init-addr libc,none',
      'log'            => 'global',
      'retries'        => '5',
      'option'         => [
        'redispatch',
        'http-server-close',
        'logasap',
      ],
      'timeout'        => [
        'http-request 7s',
        'connect 5s',
        'check 9s',
      ],
      'maxconn'        => '15000',
    },
    require          => [User['sensu'], Apt::Source['haproxy-ppa']],
    custom_fragment  => "errorfile 400 /etc/haproxy/errors/400.http
  errorfile 403 /etc/haproxy/errors/403.http
  errorfile 408 /etc/haproxy/errors/408.http
  errorfile 500 /etc/haproxy/errors/500.http
  errorfile 502 /etc/haproxy/errors/502.http
  errorfile 503 /etc/haproxy/errors/503.http
  errorfile 504 /etc/haproxy/errors/504.http";
  }

  # if we want to use mysql-check, we need to remove "port 9200" from the server line
  $check_option = $haproxy_check_method ? {
    'xinetd' => ['httpchk GET / HTTP/1.1'],
    'mysql'  => ['tcpka', 'mysql-check user haproxy'],
  }
  haproxy::listen { 'galera':
    bind        => { ':::3306' => [] },
    options     => [
      {
        'option'   => $check_option,
      },
      'mode'    => 'tcp',
      'balance' => 'source',
    ] + $galera_backends_list;
  }
}
