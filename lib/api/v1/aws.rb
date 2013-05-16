#Empowered
module Api::V1::Aws

  def s3_url_for_a_year(s3_url, filename, bucket)
    begin
      s3_url = s3_url.match(/#{get_amazon_folder}\/attachments\/\d*/).to_s + "/#{filename}"
      doomsday = Time.mktime(2037, 12, 21).to_i
      s3_url = AWS::S3::S3Object.url_for(s3_url, bucket, :expires => doomsday)
    rescue Exception => e
      Rails.logger.info("EMPOWERED: unable to find #{s3_url} in bucket #{bucket}")
      Rails.logger.info("EMPOWERED: error message : #{e.message}")
    end
    s3_url
  end

  def return_s3_url_from_attachment(attachee)
    set_up_s3
    if attachee.respond_to?(:cached_s3_url) && attachee.cached_s3_url
      s3_url = s3_url_for_a_year(attachee.cached_s3_url, attachee.filename, Empowered_s3_config[:bucket_name])
    elsif attachee.respond_to?(:s3_url)
      s3_url = s3_url_for_a_year(attachee.s3_url, attachee.filename, Empowered_s3_config[:bucket_name])
    else
      s3_url = "EMPOWERED: uh oh.. there is not an s3 url that is either cached or available"
    end
    s3_url
  end

  def set_up_s3_SNS
      unless AWS::S3::Base.connected? then
        AWS::S3::Base.establish_connection!(Empowered_s3_config.slice(:access_key_id, :secret_access_key, :server, :port, :use_ssl, :persistent, :proxy))
      end
    Empowered_s3_config
  end

  def set_up_s3
    AWS::S3::Base.establish_connection!(Empowered_s3_config.slice(:access_key_id, :secret_access_key, :server, :port, :use_ssl, :persistent, :proxy))
  end

  def get_amazon_folder(bucket="account_1")
    bucket = Account.find_by_name('empowered') ? "account_#{Account.find_by_name('empowered').id}" : bucket
    return bucket
  end

  def get_attachment(attachment_id)
    if Attachment.exists? attachment_id
      attachee = Attachment.find(attachment_id)
      url = return_s3_url_from_attachment(attachee)
    else
      Rails.logger.info "broken_link: Attachment with id #{attachment_id} has not been uploaded to cloud"
      url = ""
    end
    url
  end

  def canvas_url_to_global(link_asset)
    return link_asset if link_asset == "" or link_asset.nil?
    set_up_s3
    url = link_asset
    link_asset = link_asset.gsub(/\/courses\/\d*\/(files|file_contents)\/\d*\/preview/) do |attachment|
      attachment_id = attachment.match(/(files|file_contents)\/\d*/).to_s.split('/').last
      url = get_attachment(attachment_id)
    end
    link_asset = link_asset.gsub(/\/courses\/\d*\/(files|file_contents)\/\d*\/download\?wrap\=1/) do |attachment|
      attachment_id = attachment.match(/(files|file_contents)\/\d*/).to_s.split('/').last
      url = get_attachment(attachment_id)
    end
    if link_asset.match(/\/courses\/\d*\/file_contents\/course\%20files\/\S*\.\w{0,4}/)
    then
      link_asset = link_asset.gsub(/\/courses\/\d*\/file_contents\/course\%20files\/\S*\.\w{0,4}/) do |attachment|
        display_name = attachment.split("/").last.gsub(/\%20/, " ")
        display_name = display_name.gsub(/&amp;/, "&")
        context = attachment.split("/").third
        sql = 'select id from attachments where display_name = "'+ display_name.to_s + '" and context_id = ' + context.to_s
        attachment= Attachment.find_by_sql(sql)
        unless attachment.empty?
          attachee_id = attachment.first[:id]          
          url = get_attachment(attachee_id)
        else
          Rails.logger.info("could not find asset #{display_name} in s3")
          url = ""
        end
      end
    end
    if link_asset.match(/\/courses\/\d*\/wiki\/\S*/)
    then
      link_asset = link_asset.gsub(/\/courses\/\d*\/wiki\/\S*/) do |course_url|        
        c = Course.find(course_url.split("/").third)
        title = course_url.split("/").last
        wp = c.wiki.wiki_pages.find_by_url(title)
        unless wp.nil? 
          "/wiki/#{wp.id}"
        else
          course_url
        end  
      end
    end
    return url
  end

  def description_to_global_urls(description)
    unless description.nil? || description == ""
      h = Hpricot(description)
      h.search('a').each do |this_link|
        #wiki_page[:url] = AWS::S3::S3Objects.url_for('account_1/attachments/434/page5_1.jpg','lms-dev1-empowered-com',:expires_in => 3600 * 24 * 365 * 10)        
        if this_link['href']
          this_link['href'] = this_link['href'].gsub(/\/courses\/\d*\/(files|file_contents)\/\d*\/preview/) do |attachment|
            attachment_id = attachment.match(/(files|file_contents)\/\d*/).to_s.split('/').last
            attachee = Attachment.find(attachment_id)
            return_s3_url_from_attachment(attachee)
          end
          this_link['href'] = this_link['href'].gsub(/\/courses\/\d*\/(files|file_contents)\/\d*\/download\?wrap\=1/) do |attachment|
            attachment_id = attachment.match(/(files|file_contents)\/\d*/).to_s.split('/').last
            attachee = Attachment.find(attachment_id)
            return_s3_url_from_attachment(attachee)
          end
          if this_link['href'].match(/\/courses\/\d*\/file_contents\/course\%20files\/\S*\.\w{0,4}/)          
            this_link['href'] = this_link['href'].gsub(/\/courses\/\d*\/file_contents\/course\%20files\/\S*\.\w{0,4}/) do |attachment|
              display_name = attachment.split("/").last.gsub(/\%20/, " ")
              display_name = display_name.gsub(/&amp;/, "&")
              context = attachment.split("/").third
              sql = 'select id from attachments where display_name = "'+ display_name.to_s + '" and context_id = ' + context.to_s
              attachment= Attachment.find_by_sql(sql)
              unless attachment.empty?
                attachee_id = attachment.first[:id]
                url = get_attachment(attachee_id)
              else
                Rails.logger.info("could not find asset #{display_name} in s3")
                url = ""
              end
              url
            end
          end

          if this_link['href'].match(/\/courses\/\d*\/wiki\/\S*/)
          then
            this_link['href'] = this_link['href'].gsub(/\/courses\/\d*\/wiki\/\S*/) do |course_url|
              begin
                c = Course.find(course_url.split("/").third) # the course id is the third item
                title = course_url.split("/").last # the title is the last wiki item in the array
                wp = c.wiki.wiki_pages.find_by_url(title)
                unless wp.nil?
                  new_link = "/wiki/#{wp.id}"
                else
                  new_link = course_url
                end
              rescue Exception => e
                Rails.logger.info "error in #{__method__} - #{e.message}"
                new_link = course_url
              end
              new_link
            end
          end

          if this_link['href'].match(/\/courses\/\d*\/quizzes\/\d*/)
          then
            this_link['href'] = this_link['href'].gsub(/\/courses\/\d*\/quizzes\/\d*/) do |course_url|
              "/quiz/#{course_url.last}"
            end
          end
        end
      end
      h.search('img').each do |this_link|
        if this_link['src']
          this_link['src'] = this_link['src'].gsub(/\/courses\/\d*\/(files|file_contents)\/\d*\/preview/) do |attachment|
            attachment_id = attachment.match(/(files|file_contents)\/\d*/).to_s.split('/').last
            get_attachment(attachment_id)
          end
          this_link['src'] = this_link['src'].gsub(/\/courses\/\d*\/(files|file_contents)\/\d*\/download\?wrap\=1/) do |attachment|
            attachment_id = attachment.match(/(files|file_contents)\/\d*/).to_s.split('/').last
            get_attachment(attachment_id)
          end
          if this_link['src'].match(/\/courses\/\d*\/file_contents\/course\%20files\/\S*\.\w{0,4}/)
          then
            this_link['src'] = this_link['src'].gsub(/\/courses\/\d*\/file_contents\/course\%20files\/\S*\.\w{0,4}/) do |attachment|
              display_name = attachment.split("/").last.gsub(/\%20/, " ")
              display_name = display_name.gsub(/&amp;/, "&")
              context = attachment.split("/").third
              sql = 'select id from attachments where display_name = "'+ display_name.to_s + '" and context_id = ' + context.to_s
              attachment= Attachment.find_by_sql(sql)
              unless attachment.empty?
                attachee_id = attachment.first[:id]                
                url = get_attachment(attachee_id)
              else
                Rails.logger.info("could not find asset #{display_name} in s3")
                url = ""
              end
              url
            end
          end

          if this_link['src'].match(/\/courses\/\d*\/wiki\/\S*/)
          then
            this_link['src'] = this_link['src'].gsub(/\/courses\/\d*\/wiki\/\S*/) do |course_url|
              c = Course.find(course_url.split("/").third) # the course id is the third item
              title = course_url.split("/").last # the title is the last wiki item in the array
              wp = c.wiki.wiki_pages.find_by_url(title)
              "/wiki/#{wp.id}"
            end
          end

          if this_link['src'].match(/\/courses\/\d*\/quizzes\/\d*/)
          then
            this_link['src'] = this_link['src'].gsub(/\/courses\/\d*\/quizzes\/\d*/) do |course_url|
              "/quiz/#{course_url.last}"
            end
          end
        end
      end
      ## END hpricot h.each do
      return h.to_html
    else
      return description
    end
  end
end