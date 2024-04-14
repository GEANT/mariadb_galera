# == Define: mariadb_galera::create::root_password
#
# == Overview
#
# if the password was changed on one node, it will fail in the other nodes
# we need to let it fail and check it again, with the new password
#
# the password will be changed only if /root/.my.cnf is available, it the server
# belonged to a cluster and if the cluster status is 200
#
#
# === Parameters
#
# [*root_password*]
#   the new password for the root user
#
# [*force_ipv6*]
#   if set to true, the root password will be set for localhost and ::1
define mariadb_galera::create::root_password (
  Sensitive $root_password,
  Boolean $force_ipv6 = false
) {
  $root_cnf = '/root/.my.cnf'
  if ($force_ipv6) {
    $root_host_list = ['localhost', '::1']
  } else {
    $root_host_list = ['localhost']
  }

  # privileges ALL isn't working well with puppetlabs/mysql module on Percona 8
  # we use a function to apply a workaround (until the fix comes)
  #$root_privileges = mariadb_galera::root_privileges_workaround(['ALL'])
  file {
    default:
      mode    => '0750',
      owner   => root,
      group   => root,
      require => File['/root/bin'];
    $root_cnf:
      mode    => '0660',
      notify  => Xinetd::Service['galerachk'],
      content => Sensitive("[client]\nuser=root\npassword=${root_password.unwrap}\n");
    '/root/bin/pw_change.sh':
      content => Sensitive(
        epp("${module_name}/root_pw/pw_change.sh.epp",
          {
            'root_cnf'      => $root_cnf,
            'root_password' => Sensitive($root_password),
          }
        )
      );
    '/root/bin/old_pw_check.sh':
      content => epp("${module_name}/root_pw/old_pw_check.sh.epp", { 'root_cnf' => $root_cnf });
    '/root/bin/new_pw_check.sh':
      content => Sensitive(
        epp("${module_name}/root_pw/new_pw_check.sh.epp",
          {
            'root_password' => Sensitive($root_password)
          }
        )
      );
  }

  if ($facts['galera_rootcnf_exist'] and $facts['galera_status'] == '200') {
    exec { 'change_root_password':
      require => File[
        '/root/bin/new_pw_check.sh', '/root/bin/old_pw_check.sh', '/root/bin/pw_change.sh'
      ],
      command => 'old_pw_check.sh &>/dev/null && pw_change.sh &>/dev/null',
      path    => '/root/bin',
      unless  => 'new_pw_check.sh &>/dev/null',
      before  => File[$root_cnf];
    }
  }

  # the code below is needed if the user wants to set mysql_grant purge to true
  # it won't work in a perfect way but at least it won't break MySQL
  $root_host_list.each | $local_host | {
    mysql_grant { "root@${local_host}/*.*":
      ensure     => present,
      user       => "root@${local_host}",
      table      => '*.*',
      privileges => ['ALL'],
      require    => File[$root_cnf];
    }
  }
}
