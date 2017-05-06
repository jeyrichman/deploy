class php5 {


	$php_params = hiera('php_params')
	
	package { 'php5-fpm':
		ensure => '5.5.33+dfsg-1+deb.sury.org~trusty+2',
		require => [ apt::source['localrepo'], user['www'] ]

	}

	package { 'php5-curl': ensure => '5.5.33+dfsg-1+deb.sury.org~trusty+2', require => [ apt::source['localrepo'], user['www'] ] }
	package { 'php5-gd': ensure => '5.5.33+dfsg-1+deb.sury.org~trusty+2', require => [ apt::source['localrepo'], user['www'] ] }	
	package { 'php5-geoip': ensure => '1.1.0-2+deb.sury.org~trusty+1', require => [ apt::source['localrepo'], user['www'] ] }
	package { 'php5-imagick': ensure => '3.3.0-1+deb.sury.org~trusty+2', require => [ apt::source['localrepo'], user['www'] ] }
	package { 'php5-imap': ensure => '5.5.33+dfsg-1+deb.sury.org~trusty+2', require => [ apt::source['localrepo'], user['www'] ] }
	package { 'php5-mcrypt': ensure => '5.5.33+dfsg-1+deb.sury.org~trusty+2', require => [ apt::source['localrepo'], user['www'] ] }
	package { 'php5-memcache': ensure => '3.0.8-5+deb.sury.org~trusty+1', require => [ apt::source['localrepo'], user['www'] ] }
	package { 'php5-memcached': ensure => '2.2.0-2+deb.sury.org~trusty+1', require => [ apt::source['localrepo'], user['www'] ] }
	package { 'php5-msgpack': ensure => '0.5.5-2+deb.sury.org~trusty+1', require => [ apt::source['localrepo'], user['www'] ] }
	package { 'php5-mysqlnd': ensure => '5.5.33+dfsg-1+deb.sury.org~trusty+2', require => [ apt::source['localrepo'], user['www'] ] }
	package { 'php5-sqlite': ensure => '5.5.33+dfsg-1+deb.sury.org~trusty+2', require => [ apt::source['localrepo'], user['www'] ] }
	package { 'php5-xsl': ensure => '5.5.33+dfsg-1+deb.sury.org~trusty+2', require => [ apt::source['localrepo'], user['www'] ] }
	package { 'php5-redis': ensure => '2.2.7-1+deb.sury.org~trusty+1', require => [ apt::source['localrepo'], user['www'] ] }
	package { 'php5-xdebug': ensure => '2.3.3-3+deb.sury.org~trusty+1', require => [ apt::source['localrepo'], user['www'] ] }


	package { 'sendmail':
		ensure => installed,
	}

	file { '/etc/init.d/php-fpm':
		source => "puppet:///modules/php5/php-fpm",
        owner => 'root',
        group => 'root',
        mode => 755,
	}

	file { '/etc/php5/fpm/php.ini':
		ensure => "present",
    	owner => "root",
    	group => "root",
    	mode => 644,
    	content => template('php5/php.ini'),
    	require => Package['php5-fpm'],

	}

	file { '/etc/php5/cli/php.ini':
		ensure => "present",
    	owner => "root",
    	group => "root",
    	mode => 644,
    	content => template('php5/php.ini'),
    	require => Package['php5-fpm'],

	}

	file { '/etc/php5/fpm/pool.d/www.conf':
		ensure => "present",
    	owner => "root",
    	group => "root",
    	mode => 644,
    	content => template('php5/fpm-www.conf'),
    	require => [ Package['php5-fpm'], file['/var/log/php-fpm'] ]

	}	

	file { '/var/log/php-fpm':
		ensure => directory,
		owner => "www",
    	group => "www",
    	mode => 777,

	}

	file { '/var/log/php-errors.log':
		ensure => "present",
		owner => "www",
		group => "www",
		mode => 644,

	}

	file { '/var/log/phpmail.log':
		ensure => "present",
		owner => "www",
		group => "www",
		mode => 644,

	}

	file { '/usr/share/GeoIP':
      ensure => 'present',
      owner => 'root',
      group => 'root',
      mode => 644,
      recurse => 'remote',
      source => [ 'puppet:///modules/php5/usr/share/GeoIP' ],
      require => package['php5-geoip']
    }

	file { '/etc/sudoers.d/www-restart-php-fpm':
		source => "puppet:///modules/php5/etc/www-restart-php-fpm",
		ensure => file,
		owner => 'root',
        group => 'root',
        mode => 644,
        require => Package['sudo']
	}


	service { 'php5-fpm':
		enable      => true,
		ensure      => running,
		hasrestart => true,
		hasstatus  => true,
		restart => '/usr/bin/service php5-fpm reload',
		require    => [ file['/etc/php5/fpm/pool.d/www.conf'], file['/etc/php5/fpm/php.ini'], 
		package['php5-curl'], package['php5-gd'], package['php5-geoip'], package['php5-imagick'], package['php5-imap'], package['php5-mcrypt'], 
		package['php5-memcached'], package['php5-memcache'], package['php5-msgpack'], package['php5-mysqlnd'], package['php5-sqlite'], package['php5-xsl'] ],
		subscribe => [ file['/etc/php5/fpm/pool.d/www.conf'], file['/etc/php5/fpm/php.ini']],

	}

	file { '/var/log/php-fpm/slow.log':
		ensure => file,
		mode => 644
	}





}



