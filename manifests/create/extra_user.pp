# == Define: mariadb_galera::create::extra_user
#
# This define adds a user to an exiting DB on the galera cluster.
#
# === Parameters
#
# [*dbpass*]
#   Password for the user
#
# [*galera_servers_pattern*]
#   Pattern to match galera servers
#
# [*privileges*]
#   Privileges to grant to the user
#
# [*vip_fqdn*]
#   The FQDN of the VIP.
#
# [*table*]
#   Table to grant privileges on
#
# [*dbuser*]
#   Username to create
#
# [*ensure*]
#   Ensure the user is present or absent
#
define mariadb_galera::create::extra_user (
  Sensitive $dbpass,
  String $galera_servers_pattern,
  Optional[Stdlib::Fqdn] $vip_fqdn = undef,
  Array $privileges                = ['SELECT'],
  Variant[Array, String] $table    = '*.*',  # Example: 'schema.table', 'schema.*', '*.*'
  String $dbuser                   = $name,  # do not drop DB if a user is removed
  Enum['present', 'absent', present, absent] $ensure = present,
) {
  $galera_server_hash = puppetdb_query(
    "inventory[facts.networking.ip, facts.networking.ip6] {facts.networking.hostname ~ '${galera_servers_pattern}' \
    and facts.agent_specified_environment = '${facts['agent_specified_environment']}'}"
  )
  if $vip_fqdn =~ Undef {
    $vip_ipv4 = []
    $vip_ipv6 = []
  } else {
    $vip_ipv4 = dnsquery::a($vip_fqdn)[0]
    $vip_ipv6 = dnsquery::aaaa($vip_fqdn)[0]
  }
  $galera_ipv4 = sort(concat($galera_server_hash.map | $k, $v | { $v['facts.networking.ip'] }), $vip_ipv4)
  $galera_ipv6 = sort(concat($galera_server_hash.map | $k, $v | { $v['facts.networking.ip6'] }), $vip_ipv6)
  $galera_ips = $galera_ipv4 + $galera_ipv6

  if $table =~ String {
    $schema_name = [split($table, '[.]')[0]]
    $table_array = [$table]
  } else {
    $schema_name = $table.map |$item| { split($item, '[.]')[0] }
    $table_array = $table
  }

  $galera_ips.each | $galera_ip | {
    mysql_user { "${dbuser}@${galera_ip}":
      ensure        => $ensure,
      password_hash => mysql::password($dbpass.unwrap),
      require       => Mysql::Db[$schema_name];
    }
    mariadb_galera::create::grant { "${galera_ip} ${dbuser}":
      ensure      => $ensure,
      dbuser      => $dbuser,
      table_array => $table_array,
      privileges  => $privileges,
      source      => $galera_ip,
      require     => Mysql_user["${dbuser}@${galera_ip}"];
    }
  }
}
