# == Class: mariadb_galera
#
#
class mariadb_galera (
  Sensitive $root_password = $mariadb_galera::params::root_password
) inherits mariadb_galera::params {

  include mariadb_galera::repo
  include mariadb_galera::install
  include mariadb_galera::files
  include mariadb_galera::services
  include mariadb_galera::consul

  mariadb_galera::create::root_password { 'root':
    root_password => Sensitive($root_password),
    require       => Class['mariadb_galera::install'];
  }

  $nomad_server_hash = puppetdb_query(
    "inventory[facts.fqdn] {facts.hostname ~ 'nomad0\d' and facts.agent_specified_environment = '${::environment}'}")
  $nomad_server = sort($nomad_server_hash.map | $k, $v | {$v['facts.fqdn'] })
  echo { "test ${nomad_server}": }

}
