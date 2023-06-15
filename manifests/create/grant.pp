# == Define: mariadb_galera::create::grant
#
#
# === Parameters
#
# [*table_array*]
#   Array of tables to grant privileges to
#
# [*privileges*]
#   Privileges to grant
#
# [*dbuser*]
#   Database user to grant privileges to
#
# [*source*]
#   Source address to grant privileges from
#
# [*ensure*]
#   Ensure the grant is present or absent
#
define mariadb_galera::create::grant (
  Array $table_array,
  Array $privileges,
  String $dbuser,
  Stdlib::Ip::Address $source,
  Enum[present, absent] $ensure = present,
) {
  assert_private("this define should be called only by ${module_name}")

  $down_source = downcase($source)

  $table_array.each | $table_item | {
    mysql_grant { "${dbuser}@${down_source}/${table_item}":
      ensure     => $ensure,
      user       => "${dbuser}@${down_source}",
      table      => $table_item,
      privileges => $privileges;
    }
  }
}
