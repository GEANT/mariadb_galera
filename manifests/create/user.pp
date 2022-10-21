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
  Array[Stdlib::IP::Address, Stdlib::Fqdn] $trusted_sources = []
) {

  $galera_ips = $galera_ipv4 + $galera_ipv6

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

  if $schema_name =~ Array {
    $schema_array = $schema_name
  } else {
    $schema_array = [$schema_name]
  }

  # start '*' is not a schema that we need to create
  $schema_array_no_stars = $schema_array.filter |$item| { $item =~ Undef }

  $schema_array_no_stars.each | $myschema | {
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

  $galera_ips.each | $galera_ip | {
    mysql_user { "${dbuser}@${galera_ip}":
      ensure        => $ensure,
      password_hash => mysql_password($dbpass.unwrap),
      provider      => 'mysql',
      require       => Mysql::Db[$schema_array_no_stars];
    }
  }

  unless trusted_sources == [] {

    $_translated_trusted_sources = $trusted_sources.map |$item| {
      if item =~ Stdlib::Fqdn {
        [dns_a($item)[0], downcase(dns_aaaa($item)[0])]
      } elsif item =~ Stdlib::IP::Address::V6 { downcase(dns_aaaa($item)[0])
      } else {
        dns_a($item)[0]
      }
    }

    $translated_trusted_sources = unique(flatte($_translated_trusted_sources))

    $translated_trusted_sources.each | $item | {
      mysql_user { "${dbuser}@${item}":
        ensure        => $ensure,
        password_hash => mysql_password($dbpass.unwrap),
        provider      => 'mysql',
        require       => Mysql::Db[$schema_array_no_stars];
      }
    }
  }

}
