#!/usr/bin/env ruby
require 'rubygems'
require 'nestful'
require 'awesome_print'
 
canvas_server = "lms.dev.empowered.com"
canvas_account_id = 2
canvas_auth_token = "xxx"
class CanvasAPI
  def initialize(token,server,account_id)
    @server = server
    @token = token
    @account_id = account_id
  end
  
  # parms_new_course = {"course[name]" => "fart", "course[course_code]" => "12392"}
  # duh.create_course parms_new_course
  def create_course(parms)
    url = "https://#{@server}/api/v1/accounts/#{@account_id}/courses"
    post_parms = Hash.new
    post_parms.merge!(parms)
    post_parms.merge!("access_token"=>@token)
    begin
      result = Nestful.post url, :format => :multipart, :params =>  post_parms
      ap result
    rescue
      ap "Hmm, somthing went wrong!"
      ap result
    end
  end

  # duh.get_assigments_by_group(162)  
  def get_assigments_by_group(course_id)
    url = "https://#{@server}/api/v1/courses/#{course_id}/assignment_groups"
    parms = { "include[]" => "assignments", "page" => 1, "per_page" => "999999999999","gradable_assignments" => "true"}
    # parms.merge!("access_token" => @token)
    begin
      result = Nestful.get url, 
        :format => :json, 
        :params =>  parms,
        :headers => { "Authorization" => "Bearer #{@token}"}
        
      ap result
    rescue
      ap "Hmm, somthing went wrong!"
      ap result
    end
    
  end
  
  # duh.get_assignment_groups(162)  
  def get_assignment_groups(course_id)
    url = "https://#{@server}/api/v1/courses/#{course_id}/assignment_groups"
    begin
      result = Nestful.get url, 
        :format => :json, 
        :headers => { "Authorization" => "Bearer #{@token}"}        
      ap result
    rescue
      ap "Hmm, somthing went wrong!"
      ap result
    end
  
  end
  
  # duh.get_wikis_for_course(162)
  def get_wikis_for_course(course_id)
    url = "https://#{@server}/api/v1/courses/#{course_id}/wikis"
    begin
      result = Nestful.get url, 
        :format => :json, 
        :headers => { "Authorization" => "Bearer #{@token}"}        
      ap result
    rescue
      ap "Hmm, somthing went wrong!"
      ap result
    end
  end

  # duh.get_manafest(162)
  def get_manafest(course_id)
    url = "https://#{@server}/api/v1/manifest/#{course_id}"
    begin
      result = Nestful.get url, 
        :format => :json, 
        :headers => { "Authorization" => "Bearer #{@token}"}        
      ap result
    rescue
      ap "Hmm, somthing went wrong!"
      ap result
    end
  end
  
  # duh.get_groups(162)
  def get_groups(course_id)
    url = "https://#{@server}/api/v1/courses/#{course_id}/groups"
    begin
      result = Nestful.get url, 
        :format => :json, 
        :headers => { "Authorization" => "Bearer #{@token}"}        
      ap result
    rescue
      ap "Hmm, somthing went wrong!"
      ap result
    end
  end
  
  def get_quiz(quiz_id)
    url = "https://#{@server}/api/v1/quiz/#{quiz_id}"
    begin
      result = Nestful.get url, 
        :format => :json, 
        :headers => { "Authorization" => "Bearer #{@token}"}        
      ap result
    rescue
      ap "Hmm, somthing went wrong!"
      ap result
    end
  end
  
  def get_grades_for_student_in_courese(course_id,student_id)
    url = "https://#{@server}/api/v1/courses/#{course_id}"
    parms = { "include[]" => "total_scores", "enrollment_type" => "student", "as_user_id" => student_id}
    # parms.merge!("access_token" => @token)
    begin
      result = Nestful.get url, 
        :format => :json, 
        :params =>  parms,
        :headers => { "Authorization" => "Bearer #{@token}"}
        
      ap result
    rescue
      ap "Hmm, somthing went wrong!"
      ap result
    end

  end
  
end

duh = CanvasAPI.new(canvas_auth_token,canvas_server,canvas_account_id)
#duh.get_quiz(633)
duh.get_grades_for_student_in_courese(276,790)