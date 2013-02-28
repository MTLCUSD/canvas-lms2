class GroupsApiController < ApplicationController

  def get_groups(cat)
    groups = []
    cat.groups.each do |group|
      if group.workflow_state == "available"
        groups << {
            :groupName => group.name,
            :groupId => group.id,
            :members => group.members_json_cached
        }
      end
    end
    groups
  end

  # @API
  # List groups for a course and the students in the groups
  # provide a course id
  # @example_response
  # [{
  #    "group_category": "Project Large Group - Two Teams for Class Jeopardy",
  #    "group_category_id": 4,
  #    "groups": [{
  #        "members": [{
  #            "sections": [{
  #                "section_id": 74,
  #                "section_code": "Water Rights and Sustainability - Dev"
  #            }],
  #            "display_name": "ashleyk_student@mailinator.com",
  #            "user_id": 156,
  #            "name": "ashleyk_student@mailinator.com"
  #
  #        "group_name": "Project Group Example 1"
  #    },
  #    {
  #        "members": [{
  #            "sections": [{
  #                "section_id": 74,
  #                "section_code": "Water Rights and Sustainability - Dev"
  #            }],
  #            "display_name": "Leroy Reyes",
  #            "user_id": 170,
  #            "name": "Reyes, Leroy"
  #        },
  #        {
  #            "sections": [{
  #                "section_id": 74,
  #                "section_code": "Water Rights and Sustainability - Dev"
  #            }],
  #            "display_name": "Sachi Tunik",
  #            "user_id": 165,
  #            "name": "Tunik, Sachi"
  #      }],
  #        "group_name": "Project Group Example 2"
  #    }]
  #}]

  def get_course_student_groups()
    response = []
    course = Course.find(params[:course_id])
    course.group_categories.each do | cat |
      response << {
          :groupCategoryId => cat.id,
          :groupCategory => cat.name,
          :groups => get_groups(cat)
      }
    end
    render :json => response.to_json
  end

end
