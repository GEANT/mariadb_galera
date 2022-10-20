# == Define: galera_proxysql::create::user
#
#
define galera_proxysql::create::user (
  Sensitive $dbpass,
  $galera_hosts,
  $privileges                   = ['SELECT'],
  Variant[Array, String] $table = '*.*',  # Example: 'schema.table', 'schema.*', '*.*'
  $dbuser                       = $name,
  $force_schema_removal         = false,  # do not drop DB if a user is removed
  Enum[
    'present', 'absent',
    present, absent] $ensure    = present
) {

  if $table =~ String {
    $schema_name = split($table, '[.]')[0]
  } else {
    $schema_name = $table.map |$item| {split($item, '[.]')[0]}
  }

  if ($force_schema_removal) {
    $ensure_schema = absent
  } else {
    $ensure_schema = present
  }

  if $schema_name =~ String {
    unless defined(Mysql::Db[$schema_name]) {
      mysql::db { $schema_name:
        ensure   => $ensure_schema,
        user     => $dbuser,
        password => $dbpass.unwrap,
        grant    => $privileges,
        charset  => 'utf8',
        collate  => 'utf8_bin';
      }
    }
  } else {
    $schema_name.each | $myschema | {
      unless defined(Mysql::Db[$myschema]) {
        mysql::db { $myschema:
          ensure   => $ensure_schema,
          user     => $dbuser,
          password => $dbpass.unwrap,
          grant    => $privileges,
          charset  => 'utf8',
          collate  => 'utf8_bin';
        }
      }
    }
  }
  $galera_hosts.each | $host_name, $host_ips | {
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
    if has_key($host_ips, 'ipv6') {
      mysql_user { "${dbuser}@${host_ips['ipv6']}":
        ensure        => $ensure,
        password_hash => mysql_password($dbpass.unwrap),
        provider      => 'mysql',
        require       => Mysql::Db[$schema_name];
      }
    }
  }

}
