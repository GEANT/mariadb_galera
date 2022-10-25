# == Define: mariadb_galera::create::grant
#
#
define mariadb_galera::create::grant (
  $table,
  $privileges,
  $dbuser,
  $source,
  $ensure = present,
) {

  assert_private("this define should be called only by ${module_name}")

  if $table =~ String {
    $table_array = [$table]
  } else {
    $table_array = $table
  }

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
