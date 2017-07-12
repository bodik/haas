# generate secret
require "puppet"
module Puppet::Parser::Functions
        newfunction(:generate_secret, :type => :rvalue) do |args|
                out = Facter::Util::Resolution.exec("/bin/dd if=/dev/urandom bs=100 count=1 2>/dev/null | /usr/bin/sha256sum | /usr/bin/awk '{print $1}'")
                if out.nil?
                        return :undef
                else
                        return out
                end
        end
end
