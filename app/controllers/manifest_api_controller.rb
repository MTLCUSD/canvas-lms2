#Empowered 
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


# @API Manifest
#
# Api for showing the modules and assignments within a course - aka a manifest
class ManifestApiController < ApplicationController
  #include Api::V1::Course
  #before_filter :get_context
  ## TODO : ADD Authorize methods..
  # @API
  # List accounts that the current user can view or manage.  Typically,
  # students and even teachers will get an empty list in response, only
  # account admins can view the accounts that they are in.
  # @API
  # provides the manifest including stages as a collection of modules when given a manifest_id, which is a course id
  def generate_stages
    course_id = params[:manifest_id]

    if Course.exists?(course_id)
      manifest = get_manifest_stages(Course.find(course_id))
    else
      manifest = {:error => "course with id #{course_id} does not exist!"}
    end

    render :json => manifest.to_json
  end

  def get_manifest_stages(course)
    @course = course

    # TODO: review this, I believe it is ok not to protect this and allow it to be empty but probably need to be smarter about it
    # TODO: complete the course module in the manifest

    manifest = begin_manifest_stages()
    stages = @course.context_modules

    if manifest.length > 0 # there are modules
      stages.each do |stage|
        unless stage.deleted_at
          manifest[:stages] << {
              :stageTitle =>stage.name,
              :updated => stage.updated_at,
              :stageID => stage.id,
              :unlockAt => stage.unlock_at,
              :modules => get_assets_stages(stage.content_tags),
              :stageNumber => stage.position
          }
        end
      end
    else
      #TODO: handle this smarter when there are no modules... what do we do?
      assignments_list = @course.assignments.active
      assignments = get_assignments(assignments_list, course)
      manifest[:assignments] = assignments
    end

    return manifest
  end

  def get_assets_stages(module_assets)
    modules = []
    module_assets.each_with_index do |context_tag,i|
      if context_tag.content_type == "ContextModuleSubHeader"
        if context_tag.indent == 0 and !((context_tag.respond_to?(:deleted_at) and context_tag.deleted_at) or context_tag.respond_to?(:workflow_state) and context_tag.workflow_state == "deleted")
          # this is a module if it is at indent level 0
          this_module = {
              :moduleTitle => "",
              :moduleDescription => "",
              :assets => []
          }
          this_module[:moduleTitle] = context_tag.title
          if module_assets[i+1] and module_assets[i+1].indent == 1
          then
            this_module[:moduleDescription] = module_assets[i+1].title
          end
          assets_of_this_module_exist = true
          distance_to_assets = 2
          while assets_of_this_module_exist do
            if module_assets[i+distance_to_assets] and module_assets[i+distance_to_assets].indent == 2
            then
              this_context_asset = module_assets[i+distance_to_assets]
              this_module[:assets] << {
                  :assetID => this_context_asset.id,
                  :contentID => this_context_asset.content_id,
                  :assetTitle => this_context_asset.title,
                  :assetDescription => this_context_asset.content_type,
                  :assetMimeType => this_context_asset.content_type,
                  :moduleID => this_context_asset.context_id,
                  :updated => this_context_asset.updated_at
              }
            else
              assets_of_this_module_exist = false
            end
            distance_to_assets = distance_to_assets+1
          end
          modules << this_module
        end
        ## end if if is at level zero, meaning it's a module title
      end
      # end if contextmodulesubheader
    end
    #end loop over all module_assets
    return modules
  end


  def begin_manifest_stages()
    @course_id = @course.id
    manifest = {
        :courseID => @course_id,
        :courseTitle => @course.name,
        :courseCode => @course.course_code,
        :courseDescription => @course.syllabus_body,
        :updated => @course.updated_at,
        :resourceUrl => "manifest/#{@course_id}",
        :conclude_at => @course.conclude_at,
        :stages => []
    }
    return manifest
  end

  def get_assignments(assignments_list, course)
    assignments = []
    assignments_list.each { |assignment|
      assignments << {
          :assignmentTitle =>assignment.title,
          :assignmentDescription => "don't know how to get this yet",
          :courseID => @course_id,
          :updated => assignment.updated_at,
          :resourceUrl => "courses/#{@course.id}/assignments/#{assignment.id}",
          :group_id => assignment.assignment_group_id
      }
    }
    return assignments
  end

  # @API
  # provides the manifest when given a manifest_id, which is a course id
  def generate
    course_id = params[:manifest_id]

    if Course.exists?(course_id)
      manifest = get_manifest(Course.find(course_id))
    else
      manifest = {:error => "course with id #{course_id} does not exist!"}
    end

    render :json => manifest.to_json
  end


  def get_manifest(course)
    @course = course

    # TODO: review this, I believe it is ok not to protect this and allow it to be empty but probably need to be smarter about it
    # TODO: complete the course module in the manifest

    manifest = begin_manifest()
    course_module = @course.context_modules

    if course_module.length > 0 # there are modules
      course_module.each do |this_module|
        unless this_module.deleted_at
          manifest[:modules] << {
              :moduleTitle =>this_module.name,
              :updated => this_module.updated_at,
              :moduleID => this_module.id,
              :unlockAt => this_module.unlock_at,
              :assets => get_assets(this_module.content_tags)
          }
        end
      end
    else
      #TODO: handle this smarter when there are no modules... what do we do?
      puts("there are no modules")
      assignments_list = @course.assignments
      assignments = get_assignments(assignments_list, course)
      manifest[:assignments] = assignments

    end

    return manifest
  end

  def get_assets(module_assets)
    assets = []

    module_assets.each { |context_tag|
      resourceUrl = "todo"
      if context_tag.content_type == "Quiz" then resourceUrl = "/quiz/#{context_tag.id}" end
      if context_tag.content_type == "Attachment" then resourceUrl = Attachment.find(context_tag.context_module_id).s3_url end
      if context_tag.content_type == "WikiPage" then resourceUrl = "/wiki/#{context_tag.content_id}" end
      if context_tag.content_type == "Assignment" then resourceUrl = "/courses/#{@course_id}/items/#{context_tag.content_id}" end
      if context_tag.content_type == "Discussion" then resourceUrl = "/courses/#{@course_id}/items/#{context_tag.content_id}" end

      unless ((context_tag.respond_to?(:deleted_at) and context_tag.deleted_at) or context_tag.respond_to?(:workflow_state) and context_tag.workflow_state == "deleted")
        assets << {
            :assetID => context_tag.id,
            :contentID => context_tag.content_id,
            :assetTitle => context_tag.title,
            :assetDescription => context_tag.content_type,
            :assetMimeType => context_tag.content_type,
            :moduleID => context_tag.context_id,
            :resourceUrl => resourceUrl,
            :updated => context_tag.updated_at
        }
      end
    }
    return assets
  end

  def begin_manifest()
    @course_id = @course.id
    manifest = {
        :courseID => @course_id,
        :courseTitle => @course.name,
        :courseCode => @course.course_code,
        :courseDescription => @course.syllabus_body,
        :updated => @course.updated_at,
        :resourceUrl => "courses/#{@course_id}",
        :conclude_at => @course.conclude_at,
        :modules => []
    }

    puts "manifest: #{manifest}"
    manifest
  end

end
#Empowered end