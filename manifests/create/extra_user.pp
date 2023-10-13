# == Define: mariadb_galera::create::extra_user
#
# Add users to existing database
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
  Array $privileges             = ['SELECT'],
  Variant[Array, String] $table = '*.*',  # Example: 'schema.table', 'schema.*', '*.*'
  String $dbuser                = $name,  # do not drop DB if a user is removed
  Enum['present', 'absent', present, absent] $ensure = present,
) {
  $galera_server_hash = puppetdb_query(
    "inventory[facts.networking.ip, facts.networking.ip6] {facts.networking.hostname ~ '${galera_servers_pattern}' \
    and facts.agent_specified_environment = '${facts['agent_specified_environment']}'}"
  )
  $galera_ipv4 = sort($galera_server_hash.map | $k, $v | { $v['facts.networking.ip'] })
  $galera_ipv6 = sort($galera_server_hash.map | $k, $v | { $v['facts.networking.ip6'] })
  $galera_ips = $galera_ipv4 + $galera_ipv6

  $galera_ips = $galera_ipv4 + $galera_ipv6

  if $table =~ String {
    $schema_name = split($table, '[.]')[0]
  } else {
    $schema_name = $table.map |$item| { split($item, '[.]')[0] }
  }

  $galera_ips.each | $galera_ip | {
    mysql_user { "${dbuser}@${galera_ip}":
      ensure        => $ensure,
      password_hash => mysql_password($dbpass.unwrap),
      require       => Mysql::Db[$schema_name];
    }
    mariadb_galera::create::grant { "${galera_ip} ${dbuser}":
      ensure     => $ensure,
      dbuser     => $dbuser,
      table      => $table,
      privileges => $privileges,
      source     => $galera_ip,
      require    => Mysql_user["${dbuser}@${galera_ip}"];
    }
  }
}
