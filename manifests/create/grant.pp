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

  $table_array.each | $table_item | {
    echo { "${dbuser}@${source}/${table_item}": }
    #mysql_grant { "${dbuser}@${source}/${table_item}":
    #  ensure     => $ensure,
    #  user       => "${dbuser}@${source}",
    #  table      => $table_item,
    #  privileges => $privileges;
    #}
  }

}
