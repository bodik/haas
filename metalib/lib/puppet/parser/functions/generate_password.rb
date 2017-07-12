# generate password
require "puppet"
module Puppet::Parser::Functions
        newfunction(:generate_password, :type => :rvalue) do |args|
		outlen = args[0]

                out = Facter::Util::Resolution.exec("/bin/dd if=/dev/urandom bs=100 count=1 2>/dev/null | /usr/bin/sha256sum | /usr/bin/awk '{print $1}'")
                if out.nil?
                        return :undef
                else
			if outlen.nil?
	                        return out
			else
				return out[0, outlen]
			end
                end
        end
end
