require 'gcal4ruby'

class Calendar < ActiveRecord::Base

  include Ownable
  
  SEMESTERSTART = [2012, 8, 27]
  
  

  belongs_to :user
  belongs_to :study_session

       attr_accessible :user_id, :time_start, :time_end, :date_start, :study_session_id, :schedule_id, :days, :course_id, :course_name, :google_id

  def self.link_google(email,pass,user)
    begin
      service = GCal4Ruby::Service.new
      service.authenticate(email, pass)
      #check for existing studyhall calendar and create if doesn't exist
      studyhall_calendar = GCal4Ruby::Calendar.find(service, {:title => 'Studyhall'}).first
      if studyhall_calendar.nil?
        studyhall_calendar = GCal4Ruby::Calendar.new(service, {:title => 'Studyhall', :summary => 'Studyhall'})
        studyhall_calendar.save
        Rails.logger.info("created new studyhall calendar for #{email}")
      end
      #grab all of current user's events so we can minimize db calls
      all_user_cals = user.calendars
      all_user_cals.each do |ny|
        if(ny.schedule_id.to_i > 0 && ny.google_id.to_s == "")
          tempssh = StudySession.where(:id => ny.schedule_id).first
          if(tempssh.nil?)
            next
          else
            temptitle = tempssh.name
          end
          start_time = Time.strptime("#{ny.date_start} #{ny.time_start}", "%m/%d/%Y %I:%M %P")
          end_time = start_time + (60*60*2)
          event = GCal4Ruby::Event.new(service, {:calendar => studyhall_calendar, :title => temptitle, :start_time => start_time, :end_time => end_time, :where => "Studyhall.com"})
          event.save
          event = GCal4Ruby::Event.find(service, {:calendar => studyhall_calendar, :title => temptitle, :start_time => start_time, :end_time => end_time, :where => "Studyhall.com"})
          ny.update_attributes(:google_id => event.id)
=begin
        elsif(ny.schedule_id.to_i > 0)
          event = GCal4Ruby::Event.find(service, {:id => ny.google_id.to_s})
          start_time = Time.strptime("#{ny.date_start} #{ny.time_start}", "%m/%d/%Y %I:%M %P")
          end_time = start_time + (60*60*2)
          event.start_time = start_time
          event.end_time = end_time
          event.save
=end
        end
      end
      
      all_calendars = service.calendars
      all_calendars.each do |c|
        curr_events = c.events
        curr_events.each do |ce|
          @db_event = Calendar.where(:user_id => user.id, :google_id => ce.id).first
          Rails.logger.info("found one event") if(@db_event)
          @db_event = Calendar.new if @db_event.nil?
          startTime = ce.start_time
          @db_event.update_attributes(
            :user_id => user.id,
            :course_name => ce.title, 
            :time_start => startTime.strftime("%I:%M %P"),
            :date_start => startTime.strftime("%m/%d/%Y"),
            :google_id => ce.id
            )
        end
      end
      return true
    rescue
      return false
    end  
  end
  
  
  def Calendar.other_user_json(user)
    study_seshs = user.study_sessions
    study_seshs_ids = []
    study_seshs.each do |ss|
      study_seshs_ids << ss.id
    end
    cal_seshs = Calendar.where(:schedule_id => study_seshs_ids)
    cal_seshs_ss_ids = []
    cal_seshs.each do |cs|
      cal_seshs_ss_ids << cs.schedule_id
    end
#    study_seshs.each do |sss|
#      cal_seshs += Calendar.where(:schedule_id => sss.id)
#    end
    study_seshs_w_cal = StudySession.where(:id => cal_seshs_ss_ids)
    json_cal  = "["
      cal_seshs.each do |cal|
        sesh_temp = study_seshs_w_cal.to_ary
        sesh_name_obj = sesh_temp.find { |st| st.id == cal.schedule_id }
        sesh_name = ' ' + sesh_name_obj.name
        if sesh_name == ' '
          sesh_name = ' Study Session ' + cal.schedule_id.to_s
        end
        mdy = cal.date_start.to_s.scan(/\d+/)
        mdy[0] = mdy[0].to_i - 1
        hmampm = cal.time_start.to_s.split(' ')
        hm = hmampm[0].scan(/\d+/);
        if hm[0].to_i == 12
          if hmampm[1] == 'am'
            hm[0] = hm[0].to_i - 12
          end
        elsif hmampm[1] == 'pm'
          hm[0] = hm[0].to_i + 12
        end
        if mdy[0].to_s.empty? || mdy[1].to_s.empty? || mdy[2].to_s.empty?
          date_string = '1900,01,01'
        elsif hm[0].to_s.empty? || hm[1].to_s.empty?
          date_string = mdy[2].to_s+','+mdy[0].to_s+','+mdy[1].to_s
        else
          date_string = mdy[2].to_s+','+mdy[0].to_s+','+mdy[1].to_s+','+hm[0].to_s+','+hm[1].to_s
          full_date = true
        end
        if full_date
          end_hour = hm[0].to_i + 1
          date_string_end = mdy[2].to_s+','+mdy[0].to_s+','+mdy[1].to_s+','+end_hour.to_s+','+hm[1].to_s
          all_day_string = ', allDay: false'
        else
          date_string_end = date_string
          all_day_string = ''
        end
        json_cal << " { title: '#{sesh_name}', "
        json_cal << "start: new Date(#{date_string}), "
        json_cal << "end: new Date(#{date_string_end}), "
        json_cal << "url: 'http://www.studyhall.com/study_sessions/#{cal.schedule_id}?#{cal.id}'#{all_day_string} },"
      end
    
    class_cal = Calendar.where(!:course_id.nil?)
    
    class_cal.each do |ccl|
    
      hmampm_start = ccl.time_start.to_s.split(' ')
      hm_start = hmampm_start[0].to_s.scan(/\d+/);
      if hm_start[0].to_i == 12
        if hmampm_start[1] == 'am'
          hm_start[0] = '0'
        end
      elsif hmampm_start[1] == 'pm'
        hm_start[0] = hm_start[0].to_i + 12
      end
      
      hmampm_end = ccl.time_end.to_s.split(' ')
      hm_end = hmampm_end[0].to_s.scan(/\d+/);
      if hm_end[0].to_i == 12
        if hmampm_end[1] == 'am'
          hm_end[0] = '0'
        end
      elsif hmampm_end[1] == 'pm'
        hm_end[0] = hm_end[0].to_i + 12
      end
      
      mon = DateTime.new(SEMESTERSTART[0], SEMESTERSTART[1], SEMESTERSTART[2])
      tue = DateTime.new(SEMESTERSTART[0], SEMESTERSTART[1], SEMESTERSTART[2] + 1)
      wed = DateTime.new(SEMESTERSTART[0], SEMESTERSTART[1], SEMESTERSTART[2] + 2)
      thu = DateTime.new(SEMESTERSTART[0], SEMESTERSTART[1], SEMESTERSTART[2] + 3)
      fri = DateTime.new(SEMESTERSTART[0], SEMESTERSTART[1], SEMESTERSTART[2] + 4)
      
      monArr = ["#{mon.year},#{mon.month - 1},#{mon.day}"]
      tueArr = ["#{tue.year},#{tue.month - 1},#{tue.day}"]
      wedArr = ["#{wed.year},#{wed.month - 1},#{wed.day}"]
      thuArr = ["#{thu.year},#{thu.month - 1},#{thu.day}"]
      friArr = ["#{fri.year},#{fri.month - 1},#{fri.day}"]
      
      18.times do  
        monArr << "#{mon.year},#{mon.month - 1},#{mon.day}"
        mon += 7
        tueArr << "#{tue.year},#{tue.month - 1},#{tue.day}"
        tue += 7
        wedArr << "#{wed.year},#{wed.month - 1},#{wed.day}"
        wed += 7
        thuArr << "#{thu.year},#{thu.month - 1},#{thu.day}"
        thu += 7
        friArr << "#{fri.year},#{fri.month - 1},#{fri.day}"
        fri += 7
      end
      
      dow = ccl.days.to_s.scan(/\d/)
      course_name = ccl.course_name.to_s.split(' - ')
      dow.each do |day|
        if day == '1'
          monArr.each do |m|
            date_string_start = m + ',' + hm_start[0].to_s + ',' + hm_start[1].to_s
            date_string_end = m + ',' + hm_end[0].to_s + ',' + hm_end[1].to_s
            json_cal << " { title: '#{course_name[0]} #{course_name[1]}', "
            json_cal << "start: new Date(#{date_string_start}), "
            json_cal << "end: new Date(#{date_string_end}), "
            json_cal << "url: 'http://www.studyhall.com/classes/#{ccl.course_id}', allDay: false, editable: false, color: 'gray' },"
          end
        end
        if day == '2'
          tueArr.each do |m|
            date_string_start = m + ',' + hm_start[0].to_s + ',' + hm_start[1].to_s
            date_string_end = m + ',' + hm_end[0].to_s + ',' + hm_end[1].to_s
            json_cal << " { title: '#{course_name[0]} #{course_name[1]}', "
            json_cal << "start: new Date(#{date_string_start}), "
            json_cal << "end: new Date(#{date_string_end}), "
            json_cal << "url: 'http://www.studyhall.com/classes/#{ccl.course_id}', allDay: false, editable: false, color: 'gray' },"
          end
        end
        if day == '3'
          wedArr.each do |m|
            date_string_start = m + ',' + hm_start[0].to_s + ',' + hm_start[1].to_s
            date_string_end = m + ',' + hm_end[0].to_s + ',' + hm_end[1].to_s
            json_cal << " { title: '#{course_name[0]} #{course_name[1]}', "
            json_cal << "start: new Date(#{date_string_start}), "
            json_cal << "end: new Date(#{date_string_end}), "
            json_cal << "url: 'http://www.studyhall.com/classes/#{ccl.course_id}', allDay: false, editable: false, color: 'gray' },"
          end
        end
        if day == '4'
          thuArr.each do |m|
            date_string_start = m + ',' + hm_start[0].to_s + ',' + hm_start[1].to_s
            date_string_end = m + ',' + hm_end[0].to_s + ',' + hm_end[1].to_s
            json_cal << " { title: '#{course_name[0]} #{course_name[1]}', "
            json_cal << "start: new Date(#{date_string_start}), "
            json_cal << "end: new Date(#{date_string_end}), "
            json_cal << "url: 'http://www.studyhall.com/classes/#{ccl.course_id}', allDay: false, editable: false, color: 'gray' },"
          end
        end
        if day == '5'
          friArr.each do |m|
            date_string_start = m + ',' + hm_start[0].to_s + ',' + hm_start[1].to_s
            date_string_end = m + ',' + hm_end[0].to_s + ',' + hm_end[1].to_s
            json_cal << " { title: '#{course_name[0]} #{course_name[1]}', "
            json_cal << "start: new Date(#{date_string_start}), "
            json_cal << "end: new Date(#{date_string_end}), "
            json_cal << "url: 'http://www.studyhall.com/classes/#{ccl.course_id}', allDay: false, editable: false, color: 'gray' },"
          end
        end
      end
      

    end
    
    allGmailCals = user.calendars.where(:course_id.nil? && :schedule_id.nil? && !:course_name.nil?)
    
    allGmailCals.each do |cal|
      mdy = cal.date_start.to_s.scan(/\d+/)
        mdy[0] = mdy[0].to_i - 1
        hmampm = cal.time_start.to_s.split(' ')
        hm = hmampm[0].scan(/\d+/);
        if hm[0].to_i == 12
          if hmampm[1] == 'am'
            hm[0] = hm[0].to_i - 12
          end
        elsif hmampm[1] == 'pm'
          hm[0] = hm[0].to_i + 12
        end
        if mdy[0].to_s.empty? || mdy[1].to_s.empty? || mdy[2].to_s.empty?
          date_string = '1900,01,01'
        elsif hm[0].to_s.empty? || hm[1].to_s.empty?
          date_string = mdy[2].to_s+','+mdy[0].to_s+','+mdy[1].to_s
        else
          date_string = mdy[2].to_s+','+mdy[0].to_s+','+mdy[1].to_s+','+hm[0].to_s+','+hm[1].to_s
          full_date = true
        end
        if full_date
          end_hour = hm[0].to_i + 1
          date_string_end = mdy[2].to_s+','+mdy[0].to_s+','+mdy[1].to_s+','+end_hour.to_s+','+hm[1].to_s
          all_day_string = ', allDay: false'
        else
          date_string_end = date_string
          all_day_string = ''
        end
        json_cal << " { title: '#{cal.course_name.to_s.gsub(/'/, '')}', "
        json_cal << "start: new Date(#{date_string}), "
        json_cal << "end: new Date(#{date_string_end}), "
        json_cal << "url: 'https://www.google.com/calendar/', editable: false, color: 'green'#{all_day_string} },"
      
      
    end
    
    
    json_cal << " ]"
    json_cal
  end

end
