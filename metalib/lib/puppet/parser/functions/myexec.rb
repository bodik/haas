require "puppet"
module Puppet::Parser::Functions
	# simple wrapper for custom execs
	# 
	# @return returns command output
	# @param command line to execute using shell
        newfunction(:myexec, :type => :rvalue) do |args|
                out = Facter::Util::Resolution.exec(args[0])
                if out.nil?
                        return :undef
                else
                        return out
                end
        end
end
