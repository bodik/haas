# == Class: glog::glog2
#
# Class will ensure installation of ELK stack
#
# === Examples
#
#   class { "glog::glog2": }
#
class glog::glog2(
	$cluster_name = "glog2",
	$esd_heap_size = "1024M",
	$esd_network_host = "127.0.0.1",
	#$lsl_workers_real = 1,
) {

	# deps
	ensure_resource("service", "apache2", {})
	ensure_resource("package", "apache2", {})

	package { "apt-transport-https": ensure => installed }
	package { "openjdk-8-jdk": ensure => installed }


	
	# elk repos
	if !defined(Class['apt']) {
        	class { 'apt': }
	}
	apt::source { "elk":
		location   => "https://artifacts.elastic.co/packages/5.x/apt",
		release => "stable", repos => "main",
		include => { "src" => false },
		key => "46095ACC8548582C1A2699A9D27D666CD88E42B4",
		require => Package["apt-transport-https"],
	}




	# esd install
	package { "elasticsearch":
		ensure => installed,
		require => [Apt::Source["elk"], Exec["apt_update"], Package["openjdk-8-jdk"]],
	}
	service { "elasticsearch": 
		ensure => running,
		enable => true,
	}

	# esd config
	glog::glog2::esd_config { "-Xms":
		path => "/etc/elasticsearch/jvm.options",
		match => "^-Xms", line => "-Xms${esd_heap_size}",
	}
	glog::glog2::esd_config { "-Xmx":
		path => "/etc/elasticsearch/jvm.options",
		match => "^-Xmx", line => "-Xmx${esd_heap_size}",
	}
	# TODO: cannot manage augeas Yaml.lns
	glog::glog2::esd_config { "cluster.name":
		path => "/etc/elasticsearch/elasticsearch.yml",
		match => "^cluster.name:", line => "cluster.name: ${cluster_name}",
	}
	glog::glog2::esd_config { "http.port":
		path => "/etc/elasticsearch/elasticsearch.yml",
		match => "^http.port:", line => "http.port: 39200-39300",
	}
	glog::glog2::esd_config { "transport.tcp.port":
		path => "/etc/elasticsearch/elasticsearch.yml",
		match => "^transport.tcp.port:", line => "transport.tcp.port: 39300-39400",
	}
	glog::glog2::esd_config { "network.host":
		path => "/etc/elasticsearch/elasticsearch.yml",
		match => "^network.host:", line => "network.host: ${esd_network_host}",
	}




	# npm missing in pre-release stretch
	apt::source { "nodejs":
		location   => "https://deb.nodesource.com/node_6.x",
		release => "jessie",  repos => "main",
		include => { "src" => false },
		key => "9FD3B784BC1C6FC31A8A0A1C1655A0AB68576280",
		require => Package["apt-transport-https"],
	}
	package { "nodejs": 
		ensure => installed,
		require => [Apt::Source["nodejs"], Exec["apt_update"]],
	}
	file { "/usr/local/bin/node": ensure => link, target => "/usr/bin/nodejs", }




	# elasticsearch-head
	exec { "elasticsearch-head install":
		command => "/bin/sh /puppet/glog/bin/elastisearch-head-install.sh",
		creates => "/opt/elasticsearch-head/package.json",
		require => [Package["nodejs"], File["/usr/local/bin/node"]],
	}
	file { "/lib/systemd/system/elasticsearch-head.service":
		source => "puppet:///modules/${module_name}/elasticsearch-head/elasticsearch-head.service",
		owner => "root", group => "root", mode => "0644",
		require => Exec["elasticsearch-head install"],
	}
	file { "/opt/elasticsearch-head/Gruntfile.js":
		source => "puppet:///modules/${module_name}/elasticsearch-head/Gruntfile.js",
		owner => "root", group => "root", mode => "0644",
		require => Exec["elasticsearch-head install"],
	}
	service { "elasticsearch-head":
		ensure => running,
		enable => true,
		require => [File["/lib/systemd/system/elasticsearch-head.service"], File["/opt/elasticsearch-head/Gruntfile.js"]],
	}




	# elasticdump
	exec { "install elasticdump":
		command => "/usr/bin/npm install elasticdump -g",
		unless => "/usr/bin/npm -g list | /usr/bin/tr -c '[:print:][:cntrl:]' '?' | /bin/grep elasticdump",
		require => Package["nodejs"],
	}




	# logstash
	package { ["logstash", "libgeoip1", "geoip-database"]:
		ensure => installed,
		require => [Apt::Source["elk"], Exec["apt_update"], Package["openjdk-8-jdk"], Service["elasticsearch"]],
	}
	service { "logstash":
		ensure => running,
		enable => true,
	}

# ????
#	augeas { "/etc/default/logstash" :
#		context => "/files/etc/default/logstash",
#		changes => [
#			"set LS_OPTS \"'-w $lsl_workers_real'\"",
#		],
#		require => Package["logstash"],
#		notify => Service["logstash"],
#	}


	glog::glog2::logstash_config_file { "/etc/logstash/conf.d/10-input-udp.conf": }
	glog::glog2::logstash_config_file { "/etc/logstash/conf.d/11-input-tcp.conf": }
	glog::glog2::logstash_config_file { "/etc/logstash/conf.d/30-filter-wb.conf": }
	glog::glog2::logstash_config_file { "/etc/logstash/conf.d/50-output-es.conf": }


	# kibana
	package { "kibana": 
		ensure => installed,
		require => [Apt::Source["elk"], Exec["apt_update"], Service["elasticsearch"]],
	}
	service { "kibana":
		ensure => running,
		enable => true,
	}

	glog::glog2::kibana_config { "elasticsearch.url":
		path => "/etc/kibana/kibana.yml",
		match => "^elasticsearch.url:", line => "elasticsearch.url: \"http://${esd_network_host}:39200\"",
	}
	glog::glog2::kibana_config { "server.basePath":
		path => "/etc/kibana/kibana.yml",
		match => "^server.basePath:", line => "server.basePath: \"/kibana\"",
	}
	glog::glog2::kibana_config { "server.host":
		path => "/etc/kibana/kibana.yml",
		match => "^server.host", line => "server.host: 127.0.0.1",
	}
	glog::glog2::kibana_config { "server.port":
		path => "/etc/kibana/kibana.yml",
		match => "^server.port", line => "server.port: 5601",
	}
	file { "/lib/systemd/system/kibana.service":
		ensure => link, target => "/etc/systemd/system/kibana.service",
		require => Package["kibana"],
		before => Service['kibana'],
	}
	exec { "import kibana defaults":
		command => "/bin/sh /puppet/glog/bin/kibana-restore.sh",
		unless => "/usr/bin/curl --silent http://${esd_network_host}:39200/_cat/indices | /bin/grep .kibana",
		require => [Exec["install elasticdump"], Service["elasticsearch"], Service["logstash"]],
	}
	



	# apache proxy
	ensure_resource( 'lamp::apache2::a2enmod', "proxy", {} )
	ensure_resource( 'lamp::apache2::a2enmod', "proxy_http", {} )
	ensure_resource( 'lamp::apache2::a2enconf', "glog2", { "require" => File["/etc/apache2/conf-available/glog2.conf"] } )
	file { "/etc/apache2/conf-available/glog2.conf":
		source => "puppet:///modules/${module_name}/etc/apache2/conf-available/glog2.conf",
        	owner => "root", group => "root", mode => "0644",
	        require => [Package["apache2"], Service["elasticsearch"], Service["kibana"]],
		notify => Service["apache2"],
	}




	# defined resources
	define esd_config($path, $match, $line) { file_line { "esd config $name":
	                ensure => present,
			path => "${path}",
        	        match => "${match}",
			line => "${line}",
                	require => Package["elasticsearch"],
	                notify => Service["elasticsearch"],
	} }
	define kibana_config($path, $match, $line) { file_line { "kibana config $name":
	                ensure => present,
			path => "${path}",
        	        match => "${match}",
			line => "${line}",
                	require => Package["kibana"],
	                notify => Service["kibana"],
	} }
	define logstash_config_file() {
		file {  "${name}":
			content => template("${module_name}${name}.erb"),
			owner => "root", group => "root", mode => "0644",
			require => Package["logstash"],	notify => Service["logstash"],
	} }
}
