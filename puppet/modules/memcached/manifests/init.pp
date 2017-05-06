class memcached {


	$memcached_params = hiera('memcached_params')

	package { 'memcached': 
		ensure => installed,
		require => file['/etc/memcached.conf']
	}


	file { '/etc/memcached.conf':
		content => template('memcached/memcached.conf'),
		
	}


}
