#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

# @API Quiz
#
# API for accessing particular and general quiz information and taking quizzes.
#Empowered
class QuizApiController < ApplicationController
  before_filter :require_context, :except => [:show_quiz]

  include Api::V1::Quiz

  def add_entry
    @entry = build_entry(@topic.discussion_entries)
    if authorized_action(@topic, @current_user, :read) && authorized_action(@entry, @current_user, :create)
      has_attachment = params[:attachment] && params[:attachment].size > 0 &&
          @entry.grants_right?(@current_user, session, :attach)
      return if has_attachment && params[:attachment].size > 1.kilobytes &&
          quota_exceeded(named_context_url(@context, :context_discussion_topic_url, @topic.id))
      if save_entry
        if has_attachment
          @attachment = @context.attachments.create(:uploaded_data => params[:attachment])
          @entry.attachment = @attachment
          @entry.save
        end
        render :json => discussion_entry_api_json([@entry], @context, @current_user, session).first, :status => :created
      end
    end
  end

# @API
# Show a particular quiz for a given student id
# @example_response
#  {
#    "quiz_questions": [(1)
#    {
#    "quiz_question": {
#    "position": 1,
#    "quiz_id": 1,
#    "assessment_question_version": 0,
#    "id": 1,
#    "updated_at": "2012-05-30T14:42:27-06:00",
#    "migration_id": null,
#    "quiz_group_id": null,
#    "assessment_question_id": 1,
#    "created_at": "2012-05-30T14:42:27-06:00",
#    "question_data": {
#    "name": "who is i",
#    "neutral_comments": "",
#    "question_name": "who is i",
#    "question_text": "<p>who is i?</p>",
#    "incorrect_comments": "",
#    "correct_comments": "",
#    "points_possible": 1,
#    "assessment_question_id": null,
#    "question_type": "multiple_choice_question",
#    "answers": [(4)
#    {
#    "weight": 100,
#    "id": 9773,
#    "text": "j",
#    "comments": "good work"
#    },-
#    {
#    "weight": 0,
#    "id": 8950,
#    "text": "k",
#    "comments": ""
#    },-
#    {
#    "weight": 0,
#    "id": 5733,
#    "text": "L",
#    "comments": ""
#    },-
#    {
#    "weight": 0,
#    "id": 2592,
#    "text": "shutup",
#    "comments": ""
#    }-
#    ]-
#    }-
#    }-
#    }-
#    ],-
#    "quiz_meta": {
#    "quiz": {
#    "anonymous_submissions": false,
#    "quiz_type": "assignment",
#    "scoring_policy": "keep_highest",
#    "time_limit": null,
#    "title": "Assignment 1",
#    "assignment_id": 1,
#    "cloned_item_id": null,
#    "due_at": null,
#    "published_at": "2012-05-30T16:51:35-06:00",
#    "unlock_at": null,
#    "could_be_locked": null,
#    "id": 1,
#    "workflow_state": "available",
#    "allowed_attempts": -1,
#    "ip_filter": null,
#    "last_edited_at": "2012-05-30T14:42:27-06:00",
#    "quiz_data": [(1)
#    {
#    "published_at": "2012-05-30T15:51:35-07:00",
#    "position": 1,
#    "neutral_comments": "",
#    "name": "who is i",
#    "id": 1,
#    "question_text": "<p>who is after i?</p>",
#    "question_name": "who is after i",
#    "correct_comments": "",
#    "incorrect_comments": "",
#    "points_possible": 1,
#    "assessment_question_id": 1,
#    "answers": [(4)
#    {
#    "weight": 100,
#    "id": 9773,
#    "text": "j",
#    "comments": "good work"
#    },-
#    {
#    "weight": 0,
#    "id": 8950,
#    "text": "k",
#    "comments": ""
#    },-
#    {
#    "weight": 0,
#    "id": 5733,
#    "text": "L",
#    "comments": ""
#    },-
#    {
#    "weight": 0,
#    "id": 2592,
#    "text": "nobody",
#    "comments": ""
#    }-
#    ],-
#    "question_type": "multiple_choice_question"
#    }-
#    ],-
#    "show_correct_answers": true,
#    "context_type": "Course",
#    "description": "<p>this is the quiz that will be taken more than once by mr joshua montross as a student...  </p>",
#    "unpublished_question_count": 1,
#    "updated_at": "2012-05-30T16:51:35-06:00",
#    "migration_id": null,
#    "question_count": 1,
#    "require_lockdown_browser": null,
#    "require_lockdown_browser_for_results": null,
#    "points_possible": 1,
#    "created_at": "2012-05-30T14:39:04-06:00",
#    "deleted_at": null,
#    "hide_results": null,
#    "last_assignment_id": 1,
#    "lock_at": null,
#    "assignment_group_id": 1,
#    "context_id": 1,
#    "shuffle_answers": false
#    }-
#    }-
#  }
#
  def show_past_quizzes   # http://localhost:3000/api/v1/quiz_submissions/1?&course_id=1&user_id=2
                          # http://localhost:3000/api/v1/quiz_submissions/1?access_token=qbO0maYtubeOxe0Frea07pJ9M1iALu4Y6jLnSykCfRbCjsVFco8GUXaFNi1p3vgD&course_id=1&user_id=2
    @quiz = @context.quizzes.find(params[:quiz_id])
    @submission = @quiz.quiz_submissions.find_by_user_id_and_quiz_id(params[:user_id],params[:quiz_id])
    #render :json => @submission

    puts @submission.inspect
    unless @submission.nil?
      if authorized_action(@submission, @current_user, :read)
        if @submission
          @submission[:untaken] = @submission.untaken?
          response = @submission
        else
          response = {:error => "Couldn't find QuizSubmission with ID=#{params[:quiz_id]} AND (quiz_submissions.quiz_id = #{params[:quiz_id]})"}
        end
        render :json => response.to_json
      end
    else
      render :json => {:message => "could not find any submissions for user_id: #{params[:user_id]} and quiz_id #{params[:quiz_id]} in course #{@context.id}"}
    end

  end

  # @API
  # show a general quiz
  # @example_response
  #
  def show_quiz # http://localhost:3000/api/v1/quiz/1?quiz_id=1&course_id=1&user_id=2
                # http://localhost:3000/api/v1/quiz/1?access_token=qbO0maYtubeOxe0Frea07pJ9M1iALu4Y6jLnSykCfRbCjsVFco8GUXaFNi1p3vgD
    quiz_id = params[:quiz_id].to_i
    if Quiz.exists?(quiz_id)
      quiz = get_quiz(Quiz.find(quiz_id))
    else
      quiz = {:error => "Quiz with id #{quiz_id} does not exist!"}
    end
    if authorized_action(Quiz.find(quiz_id), @current_user, :read)
      render :json => quiz.to_json
    end
  end


  def get_quiz(quiz)
    return {
        :quiz_meta => quiz,
        :quiz_questions => quiz.quiz_questions
    }
  end

  def backup
    @quiz = @context.quizzes.find(params[:quiz_id])
    preview = params[:preview] && @quiz.grants_right?(@current_user, session, :update)
    @submission = @quiz.quiz_submissions.find_by_user_id(@current_user.id)
    @submission ||= @quiz.generate_submission(@current_user, preview)
    if @submission.completed?
    then
      @submission = @quiz.generate_submission(@current_user, false)
    end
    if (@submission && @submission.grants_right?(@current_user, session, :update))
      if !@submission.completed? && !@submission.overdue?
        @submission.backup_submission_data(params)
        return
      end
    end
    ## TODO : Allow backup via api for partial quiz completion....
    # render :json => {:backup => false, :end_at => @submission && @submission.end_at}.to_json
  end

  # @API
  # save a quiz as a student
  # @example_response
  # {
  #  "title": "Assignment 1",
  #  "scoring_policy": "keep_highest",
  #  "created_at": "2012-05-30T14:39:04-06:00",
  #  "could_be_locked": null,
  #  "assignment_group_id": 1,
  #  "overdue": false,
  #  "shuffle_answers": false,
  #  "published_at": "2012-05-30T14:42:37-06:00",
  #  "ip_filter": null,
  #  "context_type": "Course",
  #  "cloned_item_id": null,
  #  "anonymous_submissions": false,
  #  "allowed_attempts": 1,
  #  "unlock_at": null,
  #  "lock_at": null,
  #  "last_edited_at": "2012-05-30T14:42:27-06:00",
  #  "last_assignment_id": 1,
  #  "id": 1,
  #  "description": "<p>this is the quiz that will be taken more than once by mr joshua montross as a student...  </p>",
  #  "deleted_at": null,
  #  "workflow_state": "complete",
  #  "points_possible": 1,
  #  "due_at": null,
  #  "message": "success",
  #  "show_correct_answers": true,
  #  "question_count": 1,
  #  "hide_results": null,
  #  "unpublished_question_count": 1,
  #  "migration_id": null,
  #  "assignment_id": 1,
  #  "updated_at": "2012-05-30T14:42:37-06:00",
  #  "time_limit": null,
  #  "require_lockdown_browser_for_results": null,
  #  "require_lockdown_browser": null,
  #  "quiz_type": "assignment",
  #  "quiz_data": [(1)
  #  {
  #  "assessment_question_id": 1,
  #  "name": "who is i",
  #  "incorrect_comments": "",
  #  "question_type": "multiple_choice_question",
  #  "published_at": "2012-05-30T13:42:37-07:00",
  #  "id": 1,
  #  "points_possible": 1,
  #  "position": 1,
  #  "question_name": "who is i",
  #  "answers": [(4)
  #  {
  #  "text": "j",
  #  "id": 9773,
  #  "comments": "good work",
  #  "weight": 100
  #  },-
  #  {
  #  "text": "k",
  #  "id": 8950,
  #  "comments": "",
  #  "weight": 0
  #  },-
  #  {
  #  "text": "L",
  #  "id": 5733,
  #  "comments": "",
  #  "weight": 0
  #  },-
  #  {
  #  "text": "shutup",
  #  "id": 2592,
  #  "comments": "",
  #  "weight": 0
  #  }-
  #  ],-
  #  "question_text": "<p>who is i?</p>",
  #  "correct_comments": "",
  #  "neutral_comments": ""
  #  }-
  #  ],-
  #  "context_id": 1
  # }
  def save_quiz_as_student()
    redirect_params = {}
    @quiz = @context.quizzes.find(params[:quiz_id])

    # if params[:attempt].to_i > 1 and (@quiz.allowed_attempts == -1 or @quiz.allowed_attempts >= params[:attempt].to_i)
    if params[:attempt].to_i > 1
    then
      backup
      logger.info "QUIZ-API: preforming quiz backup"
    end

    @quiz.grants_right?(@current_user, :submit)
    @submission = @quiz.quiz_submissions.find_by_user_id(@current_user.id) if @current_user
    # If the submission is a preview, we don't add it to the user's submission history,
    # and it actually gets keyed by the temporary_user_code column instead of
    preview = params[:preview] && @quiz.grants_right?(@current_user, session, :update)
    @submission = nil if preview
    if !@current_user || preview
      @submission = @quiz.quiz_submissions.find_by_temporary_user_code(temporary_user_code(false))
      @submission ||= @quiz.generate_submission(temporary_user_code(false) || @current_user, preview)
    else
      @submission ||= @quiz.generate_submission(@current_user, preview)
    end

    @submission.snapshot!(params)

    previously_untaken = @submission.untaken?
    if @submission.preview? || (@submission.untaken? && @submission.attempt == params[:attempt].to_i)
      @submission.mark_completed
      hash = {}
      hash = @submission.submission_data if @submission.submission_data.is_a?(Hash) && @submission.submission_data[:attempt] == @submission.attempt
      params_hash = hash.deep_merge(params) rescue params
      @submission.submission_data = params_hash #if !@submission.overdue?
      logger.debug "@submission.submission_data : and !@submission.overdue? #{!@submission.overdue?}"
      logger.debug @submission.submission_data.inspect
      flash[:notice] = t('errors.late_quiz', "You submitted this quiz late, and your answers may not have been recorded.") if @submission.overdue?
      @submission.grade_submission
      @quiz.allowed_attempts = @quiz.allowed_attempts - 1
    end

    if session.delete('lockdown_browser_popup')
      response = {:error => "get outta here!"}
    else
      response = quiz_save_api_json(@quiz, @context, @current_user, session, @submission, previously_untaken)
    end
    render :json => response.to_json
  end

end

#Empowered end