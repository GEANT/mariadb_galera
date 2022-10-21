# Class: mariadb_galera::create::haproxy (
#
#
class mariadb_galera::create::haproxy {

  $sql_file = "CREATE USER haproxy@'%';\nGRANT PROCESS ON *.* TO 'haproxy'@'%';\nFLUSH PRIVILEGES;\n"

  exec { 'create-haproxy-user':
    command => "mysql < ${sql_file}",
    unless  => 'mysql -u haproxy -h localhost -e "select 1 from dual"',
    path    => '/bin:/sbin',
    require => Service['mariadb'];
  }

}
