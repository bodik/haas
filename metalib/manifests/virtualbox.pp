class metalib::virtualbox {
        notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	if !defined(Class['apt']) {
        	class { 'apt': }
	}
	apt::source { "virtualbox":
		location   => "http://download.virtualbox.org/virtualbox/debian",
		release => "stretch",
		repos => "contrib",
		include => { "src" => false },
		key => {
			"id" => "B9F8D658297AF3EFC18D5CDFA2F683C52980AECF",
			"source" => "https://www.virtualbox.org/download/oracle_vbox_2016.asc"
		},
	}

	package { "virtualbox-5.1":
		ensure => installed,
		require => Apt::Source["virtualbox"],
	}
}