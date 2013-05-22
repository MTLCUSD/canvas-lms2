require 'json'
require 'net/http'
require 'uri'

class ConversationObserver < ActiveRecord::Observer

  observe :conversation_message
  
  
  def after_create(record)
    Rails.logger.debug("record created in course observer - ought be conversation.")
    Rails.logger.debug(record)
    notify(record)
  end
  
  # receive a conversation_message (cm) - build json and notify esc
  def notify(cm)
  
     from = {
        :id => nil,
        :email => nil
      }
  
      begin
        from[:id] = cm.author.id
        from[:email] = User.find(from[:id].to_i).email
        body = cm.body
        # group = cm.context
        to = cm.recipients.map { |person| { :id => person.id, :email => User.find(person.id).email }}
        # puts "cm.context : #{cm.context}"
        unless cm.context == "group"
          payload = {
          	         :token => Empowered_config[:esc_token],          
                     :from    => from,
                     :created_at => cm.created_at,
                     :body => body,
                     :to => to,
                     :group_conversation => !cm.conversation.private?,
                     :conversation_id => cm.conversation.id
          }
          #Rails.logger.info("payload would be #{payload.inspect}")
          #Rails.logger.info payload.to_json
          ## TODO : use security with esc
          post(payload.to_json)
        end
        rescue
        Rails.logger.info "failed to post into esc, with conversation message id #{cm.id}"
     end
  end
  
  def get_api_host()
    #empowered = YAML.load_file("#{RAILS_ROOT}/config/empowered.yml")[RAILS_ENV].symbolize_keys rescue nil
    if Empowered_config[:api]
      return Empowered_config[:api]
    else           
      Rails.logger.info "ERROR: get_api_host not found using yaml."
    end
    
  end

  #def post(payload)
  #  begin
  #  host = "#{get_api_host}".split('/api/')[0]
  #  #Rails.logger.info "host: #{host}"
  #  req = Net::HTTP::Post.new("/api/messages/fromcanvas", initheader = {'Content-Type' =>'application/json'})
  #  #Rails.logger.info "made req of #{req} to  /api/messages/fromcanva"
  #  req.body = payload
  #  #puts "req #{req}"
  #  response = Net::HTTP.new(get_api_host, 80).start {|http| http.request(req) }
  #  puts response.body
  #  #Rails.logger.info "made post with response code #{response.code} and mesage #{response.message}"
  #  if response.code != "201"
  #    then
  #      Rails.logger.info "error: did not receive a 201 from ESC when posting to #{host} with payload #{payload.inspect}"
  #  end
  #  rescue
  #    Rails.logger.info "error: made mistake posting #{payload} to #{get_api_host}"
  #  end
  #end
   
  def post(payload)
    begin
    host = get_api_host.split('/api/')[0]
    Rails.logger.info "host: #{host}"
    req = Net::HTTP::Post.new("/api/messages/fromcanvas", initheader = {'Content-Type' =>'application/json'})
    puts req
    Rails.logger.info "made req of #{req} to  /api/messages/fromcanva"
    req.body = payload
    #puts "req #{req}"
    response = Net::HTTP.new(host, 80).start {|http| http.request(req) }
    puts response.body
    puts response.code
    #Rails.logger.info "made post with response code #{response.code} and mesage #{response.message}"
    if response.code != "201"
      then
      puts "error: did not receive a 201 from API when posting to #{host} with payload #{payload.inspect}"
        Rails.logger.info "error: did not receive a 201 from API when posting to #{host} with payload #{payload.inspect}"
        Rails.logger.info "error: did not receive a 201 from API. code : #{response.code}, body: #{response.body}, Response :#{response}"
      else
        puts "response 201 : #{response.code} and body #{response.body}"  
    
        Rails.logger.info "response 201 : #{response.code} and body #{response.body}"  
    end
    rescue
      Rails.logger.info "error: made mistake posting #{payload} to #{get_api_host}"
    end
    return response
  end

end
