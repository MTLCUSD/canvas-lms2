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
module CC
  module AssignmentResources
    
    def add_assignments
      @course.assignments.active.no_graded_quizzes_or_topics.each do |assignment|
        next unless export_object?(assignment)

        title = assignment.title rescue I18n.t('course_exports.unknown_titles.assignment', "Unknown assignment")

        if !assignment.can_copy?(@user)
          add_error(I18n.t('course_exports.errors.assignment_is_locked', "The assignment \"%{title}\" could not be copied because it is locked.", :title => title))
          next
        end

        begin
          add_assignment(assignment)
        rescue
          add_error(I18n.t('course_exports.errors.assignment', "The assignment \"%{title}\" failed to export", :title => title), $!)
        end
      end
    end

    def add_assignment(assignment)
      migration_id = CCHelper.create_key(assignment)

      lo_folder = File.join(@export_dir, migration_id)
      FileUtils::mkdir_p lo_folder

      file_name = "#{assignment.title.to_url}.html"
      relative_path = File.join(migration_id, file_name)
      path = File.join(lo_folder, file_name)

      # Write the assignment description as an .html file
      # That way at least the content of the assignment will
      # appear when someone non-canvas imports the package
      File.open(path, 'w') do |file|
        file << @html_exporter.html_page(assignment.description || '', "Assignment: " + assignment.title)
      end

      assignment_file = File.new(File.join(lo_folder, CCHelper::ASSIGNMENT_SETTINGS), 'w')
      document = Builder::XmlMarkup.new(:target=>assignment_file, :indent=>2)
      document.instruct!

      # Save all the meta-data into a canvas-specific xml schema
      document.assignment("identifier" => migration_id,
                          "xmlns" => CCHelper::CANVAS_NAMESPACE,
                          "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                          "xsi:schemaLocation"=> "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |a|
        AssignmentResources.create_assignment(a, assignment)
      end
      assignment_file.close

      @resources.resource(
              :identifier => migration_id,
              "type" => CCHelper::LOR,
              :href => relative_path
      ) do |res|
        res.file(:href=>relative_path)
        res.file(:href=>File.join(migration_id, CCHelper::ASSIGNMENT_SETTINGS))
      end
    end
    
    def self.create_assignment(node, assignment)
      node.title assignment.title
      node.due_at CCHelper::ims_datetime(assignment.due_at) if assignment.due_at
      node.lock_at CCHelper::ims_datetime(assignment.lock_at) if assignment.lock_at
      node.unlock_at CCHelper::ims_datetime(assignment.unlock_at) if assignment.unlock_at
      node.all_day_date CCHelper::ims_date(assignment.all_day_date) if assignment.all_day_date
      node.peer_reviews_due_at CCHelper::ims_datetime(assignment.peer_reviews_due_at) if assignment.peer_reviews_due_at
      node.assignment_group_identifierref CCHelper.create_key(assignment.assignment_group)
      node.grading_standard_identifierref CCHelper.create_key(assignment.grading_standard) if assignment.grading_standard
      if assignment.rubric
        assoc = assignment.rubric_association
        node.rubric_identifierref CCHelper.create_key(assignment.rubric)
        node.rubric_use_for_grading assoc.use_for_grading
        node.rubric_hide_score_total assoc.hide_score_total
        if assoc.summary_data && assoc.summary_data[:saved_comments]
          node.saved_rubric_comments do |sc_node|
            assoc.summary_data[:saved_comments].each_pair do |key, vals|
              vals.each do |val|
                sc_node.comment(:criterion_id => key){|a|a << val}
              end
            end
          end
        end
      end
      node.quiz_identifierref CCHelper.create_key(assignment.quiz) if assignment.quiz
      node.allowed_extensions assignment.allowed_extensions.join(',') unless assignment.allowed_extensions.blank?
      node.url assignment.url if ['read','watch','listen','visit'].include?(assignment.submission_types.downcase)
      atts = [:points_possible, :min_score, :max_score, :mastery_score, :grading_type,
              :all_day, :submission_types, :position, :turnitin_enabled, :peer_review_count,
              :peer_reviews_assigned, :peer_reviews, :automatic_peer_reviews,
              :anonymous_peer_reviews, :grade_group_students_individually, :freeze_on_copy]
      atts.each do |att|
        node.tag!(att, assignment.send(att)) if assignment.send(att) == false || !assignment.send(att).blank?
      end
      Rails.logger.debug("if ['read','watch','listen','visit'].include?(assignment.submission_types.downcase) : #{['read','watch','listen','visit'].include?(assignment.submission_types.downcase)}")
      if assignment.external_tool_tag
        node.external_tool_url assignment.external_tool_tag.url 
        node.external_tool_new_tab assignment.external_tool_tag.new_tab
      end
    end

  end
end
