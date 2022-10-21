# Class: mariadb_galera::create::haproxy (
#
#
class mariadb_galera::create::haproxy {


  $sql_file = "CREATE USER haproxy@'%';\nGRANT PROCESS ON *.* TO 'haproxy'@'%';\nFLUSH PRIVILEGES;\n"

  exec { 'create-haproxy-user':
    command   => "mysql --defaults-file=/root/.my.cnf -e \"${sql_file}\"",
    unless    => 'mysql --no-defaults -u haproxy -h localhost -Be "select 1 from dual"',
    path      => '/bin:/sbin',
    logoutput => true,
    require   => [Service['mariadb'], File['/root/.my.cnf']];
  }

}
