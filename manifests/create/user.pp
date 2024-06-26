# == Define: mariadb_galera::create::user
#
# This define creates a user and corresponding DB on the galera cluster.
#
# === Parameters
#
# [*dbpass*]
#   Password for the user.
#
# [*galera_servers_pattern*]
#   Pattern to match the galera servers.
#
# [*privileges*]
#   Privileges to grant to the user.
#
# [*table*]
#   Table to grant privileges on.
#
# [*dbuser*]
#   Name of the user.
#
# [*force_schema_removal*]
#   Do not drop DB if a user is removed.
#
# [*ensure*]
#   Ensure the user is present or absent.
#
# [*trusted_sources*]
#   Trusted sources for the user.
#
# [*collate*]
#   Collate for the user.
#
# [*charset*]
#   Charset for the user.
#
define mariadb_galera::create::user (
  Sensitive $dbpass,
  String $galera_servers_pattern,
  Array $privileges                = ['SELECT'],
  Variant[Array, String] $table    = '*.*',  # Example: 'schema.table', 'schema.*', '*.*'
  String  $dbuser                  = $name,
  Boolean $force_schema_removal    = false,  # do not drop DB if a user is removed
  String $collate                  = 'utf8mb3_bin',
  String $charset                  = 'utf8mb3',
  Enum['present', 'absent', present, absent] $ensure = present,
  Array[Variant[Stdlib::IP::Address, Stdlib::Fqdn, String]] $trusted_sources = [],
) {
  $galera_server_hash = puppetdb_query(
    "inventory[facts.networking.interfaces] {facts.networking.hostname ~ '${galera_servers_pattern}' \
    and facts.agent_specified_environment = '${facts['agent_specified_environment']}'}"
  )
  $galera_ips = $galera_server_hash.map |$h| {
    $h["facts.networking.interfaces"].map |$k, $v| {
      if $k != 'lo' {
        [
          if $v['bindings'] { $v['bindings'].map |$b| { $b['address'] } },
          if $v['bindings6'] { $v['bindings6'].map |$b| { if $b['address'] !~ /^fe80/ { $b['address'] } } },
        ]
      }
    }
  }.flatten.filter |$val| { $val =~ NotUndef }.sort.unique

  if $table =~ String {
    $table_array = [$table]
    $schema_name = [split($table, '[.]')[0]]
  } else {
    $table_array = $table
    $schema_name = $table.map |$item| { split($item, '[.]')[0] }
  }

  if ($force_schema_removal) {
    $ensure_schema = absent
  } else {
    $ensure_schema = present
  }

  # star '*' is not a schema that we need to create
  $schema_array_no_stars = $schema_name.filter |$item| { $item != '*' }

  $schema_array_no_stars.each | $myschema | {
    unless defined(Mysql::Db[$myschema]) {
      mysql::db { $myschema:
        ensure   => $ensure_schema,
        user     => $dbuser,
        password => $dbpass.unwrap,
        grant    => $privileges,
        charset  => $charset,
        collate  => $collate,
        require  => Service['mariadb'];
      }
    }
  }

  $galera_ips.each | $galera_ip | {
    mysql_user { "${dbuser}@${galera_ip}":
      ensure        => $ensure,
      password_hash => mysql::password($dbpass.unwrap),
      provider      => 'mysql',
      require       => Mysql::Db[$schema_array_no_stars];
    }
    -> mariadb_galera::create::grant { "${galera_ip} ${dbuser}":
      ensure      => $ensure,
      source      => $galera_ip,
      dbuser      => $dbuser,
      table_array => $table_array,
      privileges  => $privileges,
    }
  }

  unless trusted_sources == [] {
    $_translated_trusted_sources = $trusted_sources.map |$item| {
      if item =~ Stdlib::Fqdn {
        [dnsquery::a($item)[0], dnsquery::aaaa($item)[0]]
      } else {
        $item
      }
    }

    $translated_trusted_sources = unique(flatten($_translated_trusted_sources)).filter |$val| { $val =~ NotUndef }

    $translated_trusted_sources.each | $trusted_ip | {
      $down_source = downcase($trusted_ip)

      mysql_user { "${dbuser}@${trusted_ip}":
        ensure        => $ensure,
        password_hash => mysql::password($dbpass.unwrap),
        require       => Mysql::Db[$schema_array_no_stars];
      }
      -> mariadb_galera::create::grant { "${trusted_ip} ${dbuser}":
        ensure      => $ensure,
        source      => $trusted_ip,
        dbuser      => $dbuser,
        table_array => $table_array,
        privileges  => $privileges;
      }
    }
  }
}
