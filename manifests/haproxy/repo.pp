# == Class: mariadb_galera::haproxy::repo
#
# This class is responsible for configuring the apt repository for PHP 8.*
#
# === Parameters
#
# [*haproxy_repo_version*]
#   The version of the repository to use.
#
class mariadb_galera::haproxy::repo (String $haproxy_repo_version) {
  apt::key { 'haproxy-ppa':
    id     => 'CFFB779AADC995E4F350A060505D97A41C61B9CD',
    server => 'hkp://keyserver.ubuntu.com:80',
    before => Apt::Source['haproxy-ppa'],
  }
  apt::source { 'haproxy-ppa':
    location => "https://ppa.launchpadcontent.net/vbernat/haproxy-${haproxy_repo_version}/ubuntu",
    release  => $facts['os']['distro']['codename'],
    repos    => 'main',
  }
}
# vim:ts=2:sw=2
