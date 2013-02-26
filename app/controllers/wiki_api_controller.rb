
# @API Wiki
#
# API for accessing particular and general wiki information
class WikiApiController < ApplicationController
  #include Api::V1::Course
  # before_filter :get_wiki_page


  def set_up_s3
    @s3_config ||= YAML.load_file(RAILS_ROOT + "/config/amazon_s3.yml")[RAILS_ENV].symbolize_keys rescue nil
    AWS::S3::Base.establish_connection!(@s3_config.slice(:access_key_id, :secret_access_key, :server, :port, :use_ssl, :persistent, :proxy))
  end

  def get_amazon_folder(bucket="account_1")
    Account.find_by_name('empowered')? "account_#{Account.find_by_name('empowered').id}" : bucket
  end

  def return_s3_url_from_attachment(attachee)

    if attachee.respond_to?(:cached_s3_url) && attachee.cached_s3_url
      s3_url = attachee.cached_s3_url
      s3_url = s3_url.match(/#{get_amazon_folder}\/attachments\/\d*/).to_s + "/#{attachee.filename}"
      s3_url = AWS::S3::S3Object.url_for(s3_url,@s3_config[:bucket_name],:expires_in => 3600 * 24* 365 * 10)
      #puts "attachee.respond_to?(:cached_s3_url) and s3_url: #{s3_url}"
    elsif attachee.respond_to?(:s3_url)
      s3_url = attachee.s3_url
      s3_url = s3_url.match(/#{get_amazon_folder}\/attachments\/\d*/).to_s + "/#{attachee.filename}"
      s3_url = AWS::S3::S3Object.url_for(s3_url,@s3_config[:bucket_name],:expires_in => 3600 * 24* 365 * 10)
      #puts "attachee.respond_to?(:s3_url) and s3_url: #{s3_url}"
    else
      s3_url = "uh oh.. there is not an s3 url that is either cached or available"
    end
    s3_url
  end

  def convert_urls(wiki_page)
    h = Hpricot(wiki_page.body.to_s)
    h.search('a || img').each do |this_link|
      element = this_link.name == "a"? 'href' : 'src' # if it's an a tag we are looking for href and if it's not then it is an img tag and we are looking for src

      #wiki_page[:url] = AWS::S3::S3Objects.url_for('account_1/attachments/434/page5_1.jpg','lms-dev1-empowered-com',:expires_in => 3600 * 24 * 365 * 10)
      #puts "found link for wiki_api #{this_link}"
      Rails.logger.info "LOG: this link to be searched is #{this_link}"
      if this_link[element]
        this_link[element] = this_link[element].gsub(/\/courses\/\d{1,5}\/files\/\d{1,5}\/preview/) do  |attachment|
          #Rails.logger.info "LOG: ERIC #{attachment}"
          attachment_id = attachment.split("/")[4]
          attachee = Attachment.find(attachment_id)
          return_s3_url_from_attachment(attachee)
        end
      end
      if this_link[element]
        this_link[element] = this_link[element].gsub(/\/courses\/\d*\/(files|file_contents)\/\d*\/preview/) do |attachment|
          attachment_id = attachment.match(/(files|file_contents)\/\d*/).to_s.split('/').last
          attachee = Attachment.find(attachment_id)
          return_s3_url_from_attachment(attachee)
        end
      end
      #     this_link[element] = this_link[element].gsub(/\/courses\/\d*\/(files|file_contents)\/\d*\/download\?wrap\=1/) do |attachment|
      #        attachment_id = attachment.match(/(files|file_contents)\/\d*/).to_s.split('/').last
      #         attachee = Attachment.find(attachment_id)
      #         return_s3_url_from_attachment(attachee)
      #      end
      if this_link[element]
        this_link[element] = this_link[element].gsub(/\/courses\/\d{1,5}\/files\/\d{1,5}\/preview/) do  |attachment|
          #Rails.logger.info "LOG: ERIC #{attachment}"
          attachment_id = attachment.split("/")[4]
          attachee = Attachment.find(attachment_id)
          return_s3_url_from_attachment(attachee)
        end
      end

      if this_link[element]
      then
        this_link[element] = this_link[element].gsub(/\/courses\/\d*\/file_contents\/course\%20files\/\S*\.\w{0,4}/) do |attachment|
          display_name = attachment.split("/").last.gsub(/\%20/," ")
          display_name = display_name.gsub(/&amp;/,"&")
          context = attachment.split("/").third
          sql = 'select id from attachments where display_name = "'+ display_name.to_s + '" and context_id = ' + context.to_s
          #puts sql
          Rails.logger.info "sql of #{sql}"
          unless Attachment.find_by_sql(sql).empty?
            attachee_id = Attachment.find_by_sql(sql).first[:id]
            #puts "found an attachee_id of #{attachee_id}"
            attachment = return_s3_url_from_attachment(Attachment.find(attachee_id))
          else
            Rails.logger.info "sql of #{sql} resulted in no results...context :#{context} and display-name of #{display_name} for attachment #{attachment}"
          end
          attachment
        end
      end

      if this_link[element]
      then
        #puts "finding matches of links with wkis"
        this_link[element] = this_link[element].gsub(/\/courses\/\d*\/wiki\/\S*/) do |course_url|
          c = Course.find(course_url.split("/").third)
          title = course_url.split("/").last
          #               wp = c.wiki.wiki_pages.find_by_sql('select id from wiki_pages where title="'+title+'"')/wik
          #               get_wiki_page
          #              "/wiki/#{wp[0]['id']}"
          wp = c.wiki.wiki_pages.find_by_url(title)
          Rails.logger.info("wp.id #{wp.id}")
          "/wiki/#{wp.id}"
        end
      end
      if this_link[element]
      then
        this_link[element] = this_link[element].gsub(/\/courses\/\d*\/quizzes\/\d*/) do |course_url|
          "/quiz/#{course_url.last}"
        end
      end

    end
    ## END hpricot loop over links
    h.to_html
  end
  ## end method convert_urls

  # @API
  # show a unique wiki given a wiki_id
  def generate
    wiki_id = params[:wiki_id]
    set_up_s3
    if WikiPage.exists?(wiki_id) and is_authorized_action?(WikiPage.find(params[:wiki_id]), @current_user, :read)
      # was using Wiki.find(wiki_id)... but that is wrong. the wiki.find(id) finds top level wiki for course...
      wiki_page = WikiPage.find(wiki_id)
      set_up_s3
      wiki_page.body = convert_urls(wiki_page)
    else
      wiki_page = {:error => "wiki with id #{wiki_id} does not exist... or you are not authorized!"}
    end
#      wiki_page.body = h.to_html
    render :json => wiki_page.to_json
  end

  # @API
  # show all the wikis in a course
  def show_course_wikis
    course = Course.find(params[:course_id])
    wiki = course.wiki
    pages = []
    set_up_s3
    unless wiki.wiki_pages.nil?
      pages = wiki.wiki_pages.map do |page|
        #page.body= convert_urls(page)
        page.body=convert_urls(page)
        page
      end
    end
    render :json => {
        :wiki => wiki,
        :wiki_pages => pages
    }
  end

  def get_sub_pages(manifest)
    sub_pages = []
    manifest.wiki_pages.each{|page|
      unless page.hide_from_students == true
        sub_pages << {
            :title => page.title,
            :body => page.body,
            :comments_count => page.wiki_page_comments_count,
            :url => page.url,
            :delayed_post_at => page.delayed_post_at,
            :sub_page_id => page.id
        }
      end
    }
    sub_pages
  end

end
