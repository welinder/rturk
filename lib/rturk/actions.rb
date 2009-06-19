module RTurk::Actions
  # Overides createHIT to allow for easier entry
  def create_hit(props, page)
    props = format_props(props)
    p props = props.merge(:Question => page, :Operation => 'CreateHIT')
    request(props)
  end
  
  # Attempt to expire hit, then approve assignments, and finally dispose of
  def kill_hit(hit_id)
    p forceExpireHIT(:HITId => hit_id)
    get_assignments_for_hit(hit_id).each do |assignment|
      p approveAssignment(:AssignmentId => assignment[:AssignmentId])
    end
    p disposeHIT(:HITId => hit_id)
  end
  
  # Wipe out all HIT's associated with this account
  def blank_slate
    
  end
  
  
  def get_assignments_for_hit(hit)
    response = request(:Operation => 'GetAssignmentsForHIT', :HITId => hit)
    assignments = []
    if response['GetAssignmentsForHITResult']['Assignment'].instance_of?(Array)
      response['GetAssignmentsForHITResult']['Assignment'].each do |assignment|
        answer = RTurk::Answer.parse(assignment['Answer'])
        assignment.delete('Answer')
        assignment['Answer'] = answer
        assignments << assignment
      end
    else
      assignment = response['GetAssignmentsForHITResult']['Assignment']
      answer = RTurk::Answer.parse(response['GetAssignmentsForHITResult']['Assignment']['Answer'])
      assignment.delete('Answer')
      assignment['Answer'] = answer
      assignments << assignment
    end
    assignments
  end
  
  def url_for_hit(hit_id)
    url_for_hit_type(getHIT(:HITId => hit_id)[:HITTypeId])
  end
  
  def url_for_hit_type(hit_type_id)
    if @host =~ /sandbox/
      "http://workersandbox.mturk.com/mturk/preview?groupId=#{hit_type_id}" # Sandbox Url
    else
      "http://mturk.com/mturk/preview?groupId=#{hit_type_id}" # Production Url
    end
  end

  private

  def format_props(params)
    reward = params[:Reward]
    qualifiers = params[:QualificationRequirement]
    params.delete(:Reward)
    params.delete(:QualificationRequirement)
    params.merge!('Reward.1.Amount' => reward[:Amount], 'Reward.1.CurrencyCode' => reward[:CurrencyCode])
    qualifiers.each_with_index do |qualifier, i|
      params["QualificationRequirement.#{i+1}.QualificationTypeId"] = qualifier[:QualificationTypeId]
      params["QualificationRequirement.#{i+1}.Comparator"] = qualifier[:Comparator]
      params["QualificationRequirement.#{i+1}.IntegerValue"] = qualifier[:IntegerValue]
    end
    params
  end

end
