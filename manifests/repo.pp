# == Class: mariadb_galera
#
#
class mariadb_galera::repo {

  apt::key {
    'mariadb-server':
      id => 'CE1A3DD5E3C94F49';
    'mariadb-tools':
      id => 'F1656F24C74CD1D8';
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
