module EPPClient
  module Session
    # Sends an hello epp command.
    def hello
      send_request(command do |xml|
        xml.hello
      end)
    end

    def login_xml(new_pw = nil) #:nodoc:
      command do |xml|
        xml.login do
          xml.clID(@client_id)
          xml.pw(@password)
          xml.newPW(new_pw) unless new_pw.nil?
          xml.options do
            xml.version(@version)
            xml.lang(@lang)
          end
          xml.svcs do
            services.each do |s|
              xml.objURI(s)
            end
            unless extensions.empty?
              xml.svcExtension do
                extensions.each do |e|
                  xml.extURI(e)
                end
              end
            end
          end
        end
      end
    end
    private :login_xml

    # Perform the login command on the server. Takes an optionnal argument, the
    # new password for the account.
    def login(new_pw = nil)
      response = send_request(login_xml(new_pw))

      get_result(response)
    end

    # Performs the logout command, after it, the server terminates the
    # connection.
    def logout
      response = send_request(command do |xml|
        xml.logout
      end)

      get_result(response)
    end
  end
end
