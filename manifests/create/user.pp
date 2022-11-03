# == Define: mariadb_galera::create::user
#
#
define mariadb_galera::create::user (
  Sensitive $dbpass,
  $galera_ipv4,
  $galera_ipv6                  = [],
  $privileges                   = ['SELECT'],
  Variant[Array, String] $table = '*.*',  # Example: 'schema.table', 'schema.*', '*.*'
  $dbuser                       = $name,
  $force_schema_removal         = false,  # do not drop DB if a user is removed
  Enum['present', 'absent', present, absent] $ensure = present,
  Optional[Array[Variant[Stdlib::IP::Address, Stdlib::Fqdn, String]]] $trusted_sources = [],
  $collate = 'utf8mb3_bin',
  $charset = 'utf8mb3'
) {

  $galera_ips = $galera_ipv4 + $galera_ipv6

  if $table =~ String {
    $schema_name = [split($table, '[.]')[0]]
  } else {
    $schema_name = $table.map |$item| {split($item, '[.]')[0]}
  }

  if ($force_schema_removal) {
    $ensure_schema = absent
  } else {
    $ensure_schema = present
  }

  # start '*' is not a schema that we need to create
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

    echo { "${galera_ip} ${dbuser} ${ensure} ${galera_ip} ${dbuser} ${schema_name} ${privileges}":; }

    mysql_user { "${dbuser}@${galera_ip}":
      ensure        => $ensure,
      password_hash => mysql_password($dbpass.unwrap),
      provider      => 'mysql',
      require       => Mysql::Db[$schema_array_no_stars];
    }
    mariadb_galera::create::grant { "${galera_ip} ${dbuser}":
      ensure     => $ensure,
      source     => $galera_ip,
      dbuser     => $dbuser,
      table      => $schema_name,
      privileges => $privileges,
      require    => Mysql_user["${dbuser}@${galera_ip}"]
    }
  }

  unless trusted_sources == [] {
    $_translated_trusted_sources = $trusted_sources.map |$item| {
      if item =~ Stdlib::Fqdn {
        [dns_a($item)[0], dns_aaaa($item)[0]]
      } else {
        $item
      }
    }

    $translated_trusted_sources = unique(flatten($_translated_trusted_sources)).filter |$val| { $val =~ NotUndef }

    $translated_trusted_sources.each | $trusted_ip | {

      echo { "${trusted_ip} ${dbuser} ${ensure} ${trusted_ip} ${dbuser} ${table} ${privileges}":; }

      mysql_user { "${dbuser}@${trusted_ip}":
        ensure        => $ensure,
        password_hash => mysql_password($dbpass.unwrap),
        provider      => 'mysql',
        require       => Mysql::Db[$schema_array_no_stars];
      }
      -> mariadb_galera::create::grant { "${trusted_ip} ${dbuser}":
        ensure     => $ensure,
        source     => $trusted_ip,
        dbuser     => $dbuser,
        table      => $table,
        privileges => $privileges;
      }
    }
  }

}
