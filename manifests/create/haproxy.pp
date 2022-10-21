# Class: mariadb_galera::create::haproxy (
#
#
class mariadb_galera::create::haproxy {


  $sql_file = "CREATE USER haproxy@'%';\nGRANT PROCESS ON *.* TO 'haproxy'@'%';\nFLUSH PRIVILEGES;\n"
  notify { "bofh ${sql_file}": }

  exec { 'create-haproxy-user':
    command   => "mysql -e \"${sql_file}\"",
    unless    => 'mysql -u haproxy -h localhost -e "select 1 from dual"',
    path      => '/bin:/sbin',
    logoutput => true,
    require   => Service['mariadb'];
  }

}
