module Api::V1::Quiz
  include Api::V1::Json
  def quiz_save_api_json(quiz, context, user, session, submission, previously_untaken)
      json = api_json(quiz, user, session)
      if submission.workflow_state == 'complete' && previously_untaken
        json[:message] = "success"
        json[:overdue] = submission.overdue?
        json[:workflow_state] = submission.workflow_state
      else
        json[:message] = 'failure'
        json[:previously_untaken] = previously_untaken
        json[:overdue] = submission.overdue?
        json[:workflow_state] = submission.workflow_state
      end
      json
  end
end