class EmpoweredQuizApiController < ApplicationController
 include Api::V1::Quiz
  @@errors = {
    :quiz_not_found => "Quiz not found"
  }

  #https://ec2-54-198-192-100.compute-1.amazonaws.com/api/v1/empowered_api/quiz_show_extra_attempts.json?updated_at_date=2014-04-09%2023:38:50
  def quiz_show_extra_attempts 
    return unless authorized_action(Account.site_admin, @current_user, :become_user)
    updated_at_date = params[:updated_at].to_s
    result = QuizSubmission.where("extra_attempts > 0").where("updated_at >= ?", updated_at_date ).select([:user_id,:quiz_id,:updated_at,:created_at,:extra_attempts])
    render :json => result.to_json
  end
end

