# ./script/runner ./script/find-mp4.rb
def get_course_title(cid)
  begin
    duh = Course.find(cid)
    duh.name
  rescue
    ""
  end
end


duh = Assignment.where("workflow_state = 'published'")
duh.each do |ass|
  desc = ass.description.nil? ? "" : ass.description
  if desc.include? "mp4"
    result = []
    result.push ass.id
    result.push ass.title.nil? ? "" : ass.title
    result.push get_course_title(ass.context_id)
    if !ass.description.nil?
      doc = Hpricot(ass.description)
      item = doc.search("a").first
      if !item.nil?
        result.push item["title"].nil? ? "" : item["title"]
      end
    end
    puts result.join(',')

  end
end