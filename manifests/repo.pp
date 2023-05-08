# == Class: mariadb_galera::repo
#
#
class mariadb_galera::repo {
  apt::key {
    'mariadb-server':
      id => '4C470FFFEFC4D3DC59778655CE1A3DD5E3C94F49';
    'mariadb-tools':
      id => '177F4010FE56CA3336300305F1656F24C74CD1D8';
  }

  apt::source {
    default:
      include      => {
        'deb' => true,
      },
      architecture => $facts['architecture'],
      notify       => Exec['apt_update'],
      require      => Apt::Key['mariadb-server', 'mariadb-tools'];
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
