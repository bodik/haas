#pulls vals from warden config file
require "puppet"
require "json"
module Puppet::Parser::Functions
        newfunction(:warden_config_secret, :type => :rvalue) do |args|
		out = nil
		begin
			data = JSON.parse(File.read(args[0]))
			out = data['secret']
		rescue Exception => e
		end
                if out.nil?
                        return :undef
                else
                        return out
                end
        end
end
