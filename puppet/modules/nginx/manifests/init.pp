class nginx {


    $whitelist=hiera('rate_limit_white_list')
    $nginx_params = hiera('nginx_params')
  
    package { 'nginx':
      ensure => '1.8.1-1~trusty-graphite',
      require => [ apt::source['aptly_localrepo'],user['www'] ]
    }

    file { "/etc/nginx/nginx.conf":
      ensure => "present",
      owner => "root",
      group => "root",
      mode => 644,
      content => template('nginx/nginx.conf'),
      require => [ Package['nginx'], File['/etc/nginx'] ],
    }

  file { "/etc/nginx/conf.d/whitelist":
      ensure => "present",
      owner => "root",
      group => "root",
      mode => 644,
      content => template('nginx/whitelist'),
      require => [ Package['nginx'], File['/etc/nginx'] ],
    }

  file { "/etc/nginx/conf.d/010-servers.conf":
      ensure => "present",
      owner  => "root",
      group  => "root",
      mode   => 644,
      content => template('nginx/010-servers.conf'),
      require => [ Package['nginx'], File['/etc/nginx'] ],
    }

  file { "/etc/logrotate.d/nginx":
      ensure => "present",
      owner => "root",
      group => "root",
      mode => 644,
      source => [ 'puppet:///modules/nginx/etc/logrotate.d/nginx' ],
      require => Package['nginx'],
    }

    file { '/etc/nginx':
      ensure => 'present',
      owner => 'root',
      group => 'root',
      mode => 644,
      recurse => 'true',
      purge   => true,
      source => [ 'puppet:///modules/nginx/etc/nginx' ],
    }


    file { "/etc/nginx/conf.d/005-ratelimits.conf":
      ensure => "present",
      owner => "root",
      group => "root",
      mode => 600,
      source => [ "puppet:///modules/nginx/custom/etc/nginx/conf.d/005-ratelimits.conf.${hostname}", "puppet:///modules/nginx/custom/etc/nginx/conf.d/005-ratelimits.conf",
      ],
    }

    file { "/etc/nginx/conf.d/015-ssl.conf":
      ensure => "present",
      owner => "root",
      group => "root",
      mode => 600,
      source => [ "puppet:///modules/nginx/custom/etc/nginx/conf.d/015-ssl.conf.${hostname}", "puppet:///modules/nginx/custom/etc/nginx/conf.d/015-ssl.conf",
      ],
    }


    file { '/var/www':
      ensure => 'present',
      owner => 'www',
      group => 'www',
      mode => 755,
      recurse => 'remote',
      source => [ 'puppet:///modules/nginx/var/www' ],
      require => User['www']
    }

      file { '/var/www/lib':
      ensure => 'directory',
      owner => 'www',
      group => 'www',
      mode => 755,
      require => [ File['/var/www'], User['www'] ]
    }

    file { '/var/www/session':
      ensure => 'directory',
      owner => 'www',
      group => 'www',
      mode => 755,
      require => [ File['/var/www'], User['www'] ]
    }

  user { 'www':
      ensure => present,
      home => '/var/www',
      shell => '/bin/bash',
      managehome => true,

  }

  file { '/var/log/nginx':
    ensure => 'directory',
    owner => 'www',
    group => 'www',
    mode => 755,
    require => User['www']
  }

  file { "/var/www/.ssh":
    owner =>  "www",
    group => "www",
    ensure => "directory",
    mode => 700,
    require => User["www"],
 }

  file { "/var/www/.ssh/authorized_keys":
    ensure => "present",
    owner => "www",
    group => "www",
    mode => 600,
    source => "puppet:///modules/nginx/authorized_keys_deploy",
    require => User["www"],
  }


  service { 'nginx':
      ensure => running,
      enable => true,
      subscribe => File['/etc/nginx/nginx.conf']
  }


}

