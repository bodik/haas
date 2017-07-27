require "puppet"
module Puppet::Parser::Functions
	# simple wrapper for avahi-browse
	#
	# @return string or hostname representing discovered service
	# @param arg0 name of the service to discover
	newfunction(:avahi_findservice, :type => :rvalue) do |args|
		out= Facter::Util::Resolution.exec('/puppet/metalib/bin/avahi_findservice.sh '+args[0])
		if out.nil?
			return :undef
		else
			return out
		end
	end
end
