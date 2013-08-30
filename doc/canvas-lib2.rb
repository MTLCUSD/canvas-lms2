#!/usr/bin/env ruby
require 'rubygems'
require "awesome_print"
require 'nestful'

canvas_server = "http://localhost:3000"
canvas_account_id = 1
canvas_auth_token = "QRc8Q1QKvHU0V8J2aLasmFbKQSZXJQFvIOkVTe0UbsOOApqO7FtZglTxM8dQKQlg"
class CanvasAPI
  def initialize(token,server,account_id)
    @server = server
    @token = token
    @account_id = account_id
  end
  
  # parms_new_course = {"course[name]" => "fart", "course[course_code]" => "12392"}
  # duh.create_course parms_new_course
  def create_course(parms)
    url = "#{@server}/api/v1/accounts/#{@account_id}/courses"
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
    url = "#{@server}/api/v1/courses/#{course_id}/assignment_groups?access_token=#{@token}"
    parms = { "include[]" => "assignments", "page" => 1, "per_page" => "999999999999","gradable_assignments" => "true"}
    # parms.merge!("access_token" => @token)
    begin
      result = Nestful.get url, 
        :format => :json, 
        :params =>  parms
        
      ap result.as_json
    rescue
      ap "Hmm, somthing went wrong!"
      ap result
    end
    
  end
  
  # duh.get_assignment_groups(162)  
  def get_assignment_groups(course_id)
    url = "#{@server}/api/v1/courses/#{course_id}/assignment_groups?access_token=#{@token}"
    begin
      result = Nestful.get url, 
        :format => :json       
      ap result.as_json
    rescue
      ap "Hmm, somthing went wrong!"
      ap result
    end
  
  end
  
  # duh.get_wikis_for_course(162)
  def get_wikis_for_course(course_id)
    url = "#{@server}/api/v1/courses/#{course_id}/wikis?access_token=#{@token}"
    begin
      result = Nestful.get url, 
        :format => :json        
      ap result.as_json
    rescue
      ap "Hmm, somthing went wrong!"
      ap result
    end
  end

  # duh.get_manafest(162)
  def get_manafest(course_id)
    url = "#{@server}/api/v1/manifest/#{course_id}?access_token=#{@token}"
    begin
      result = Nestful.get url, 
        :format => :json         
      ap result.as_json
    rescue
      ap "Hmm, somthing went wrong!"
      ap result
    end
  end
  
  # duh.get_groups(162)
  def get_groups(course_id)
    url = "#{@server}/api/v1/courses/#{course_id}/groups?access_token=#{@token}"
    begin
      result = Nestful.get url, 
        :format => :json 
                
      ap result.as_json
    rescue
      ap "Hmm, somthing went wrong!"
      ap result
    end
  end
  
  #duh.get_quiz(1)
  def get_quiz(quiz_id)
    url = "#{@server}/api/v1/quiz/#{quiz_id}?access_token=#{@token}"
    begin
      result = Nestful.get url, 
        :format => :json    
      ap result.as_json
    rescue
      ap "Hmm, somthing went wrong!"
      ap result
    end
  end
  
  #duh.get_grades_for_student_in_courses(course_id,student_id)
  def get_grades_for_student_in_courses(course_id,student_id)
    url = "#{@server}/api/v1/courses/#{course_id}"
    parms = { "include[]" => "total_scores", "enrollment_type" => "student", "as_user_id" => student_id}
    # parms.merge!("access_token" => @token)
    begin
      result = Nestful.get url, 
        :format => :json,
        :headers => { "Authorization" => "Bearer #{@token}"},
        :params =>  parms
        

        
      ap result
      puts url
    rescue
      ap "Hmm, somthing went wrong!"
      ap result
      puts url
    end

  end

  def test(course_id)
    url = "#{@server}/api/v1/courses/#{course_id}?access_token=#{@token}"
    begin
      result = Nestful.get url, 
        :format => :json
      ap result.as_json
    rescue
      ap "Hmm, somthing went wrong!"
      ap result
    end
  end


  
end

duh = CanvasAPI.new(canvas_auth_token,canvas_server,canvas_account_id)
#duh.get_assigments_by_group(11)
#duh.get_assignment_groups(11)
#duh.get_wikis_for_course(11)
#duh.get_manafest(11)
#duh.get_groups(11)
#duh.get_quiz(1)
#duh.get_grades_for_student_in_courses(17,1)
#duh.get_grades_for_student_in_courese(276,790)
#duh.get_groups(11) 
duh.test(3)

