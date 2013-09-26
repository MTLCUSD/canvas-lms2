# @API Wiki
#
# API for accessing particular and general wiki information
class WikiApiController < ApplicationController
  
  # @API
  # show a unique wiki given a wiki_id
  def generate
    wiki_id = params[:wiki_id]
    if WikiPage.exists?(wiki_id) and is_authorized_action?(WikiPage.find(params[:wiki_id]), @current_user, :read)
      # was using Wiki.find(wiki_id)... but that is wrong. the wiki.find(id) finds top level wiki for course...
      wiki_page = WikiPage.find(wiki_id)
      wiki_page.body
    else
      wiki_page = {:error => "wiki with id #{wiki_id} does not exist... or you are not authorized!"}
    end
    render :json => wiki_page.to_json
  end

  # @API
  # show all the wikis in a course
  def show_course_wikis
    course = Course.find(params[:course_id])
    wiki = course.wiki
    pages = []
    unless wiki.wiki_pages.nil?
      pages = wiki.wiki_pages.map do |page|
        page.body
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