# == Define: mariadb_galera::create::extra_user
#
# Add users to existing database
#
define mariadb_galera::create::extra_user (
  Sensitive $dbpass,
  String $database,
  $galera_hosts                 = undef,
  $proxysql_hosts               = {},
  $proxysql_vip                 = {},
  $privileges                   = ['SELECT'],
  Variant[Array, String] $table = '*.*',  # Example: 'schema.table', 'schema.*', '*.*'
  $dbuser                       = $name,  # do not drop DB if a user is removed
  Enum[
    'present', 'absent',
    present, absent] $ensure    = present,
) {

  if ($proxysql_hosts) {
    $host_hash = deep_merge($galera_hosts, $proxysql_hosts, $proxysql_vip)
  } else {
    $host_hash = $galera_hosts
  }

  if $table =~ String {
    $schema_name = split($table, '[.]')[0]
  } else {
    $schema_name = $table.map |$item| {split($item, '[.]')[0]}
  }

  if ($galera_hosts) {
    $host_hash.each | $host_name, $host_ips | {
      mysql_user {
        "${dbuser}@${host_ips['ipv4']}":
          ensure        => $ensure,
          password_hash => mysql_password($dbpass.unwrap),
          provider      => 'mysql',
          require       => Mysql::Db[$schema_name];
        "${dbuser}@${host_name}":
          ensure        => $ensure,
          password_hash => mysql_password($dbpass.unwrap),
          provider      => 'mysql',
          require       => Mysql::Db[$schema_name];
      }
      mariadb_galera::create::grant {
        default:
          ensure     => $ensure,
          dbuser     => $dbuser,
          table      => $table,
          privileges => $privileges;
        "${host_ips['ipv4']} ${dbuser}":
          source  => $host_ips['ipv4'],
          require => Mysql_user["${dbuser}@${host_ips['ipv4']}"];
        "${host_name} ${dbuser}":
          source  => $host_name,
          require => Mysql_user["${dbuser}@${host_name}"];
      }
      if has_key($host_ips, 'ipv6') {
        mysql_user { "${dbuser}@${host_ips['ipv6']}":
          ensure        => $ensure,
          password_hash => mysql_password($dbpass.unwrap),
          provider      => 'mysql',
          require       => Mysql::Db[$schema_name];
        }
        mariadb_galera::create::grant { "${host_ips['ipv6']} ${dbuser}":
          ensure     => $ensure,
          source     => $host_ips['ipv6'],
          dbuser     => $dbuser,
          table      => $table,
          privileges => $privileges,
          require    => Mysql_user["${dbuser}@${host_ips['ipv6']}"]
        }
      }
    }
  } else {
    fail('hash galera_hosts not defined')
  }

}