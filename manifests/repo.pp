# == Class: mariadb_galera
#
#
class mariadb_galera::repo {

  apt::key { 'mariadb':
    id     => '199369E5404BD5FC7D2FE43BCBCB082A1BB943DB',
    source => 'https://supplychain.mariadb.com/MariaDB-Server-GPG-KEY'
  }

  apt::source {
    default:
      include      => {
        'src' => true,
        'deb' => true,
      },
      architecture => $facts['architecture'],
      notify       => Exec['apt_update'],
      require      => Apt::Key['mariadb'];
    'mariadb-server':
      location => 'https://dlm.mariadb.com/repo/mariadb-server/10.9/repo/ubuntu',
      release  => $facts['lsbdistcodename'],
      repos    => 'main';
    'mariadb-tools':
      location => 'http://downloads.mariadb.com/Tools/ubuntu',
      release  => $facts['lsbdistcodename'],
      repos    => 'main';
  }

}
