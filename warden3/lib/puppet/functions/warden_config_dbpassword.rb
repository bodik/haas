require "json"
Puppet::Functions.create_function(:warden_config_dbpassword) do
	# gets db password from warden config file
	#
	# @return password string
	# @param path confifile path
        def warden_config_dbpassword(path)
		out = nil
		begin
			data = JSON.parse(File.read(path))
			out = data['DB']['password']
		rescue Exception => e
		end
                if out.nil?
                        return :undef
                else
                        return out
                end
        end
end
