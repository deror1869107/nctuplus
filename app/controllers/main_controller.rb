class MainController < ApplicationController
  #require 'coderay'
  require 'open-uri'
  require 'net/http'
  require 'json'
	layout false, :only => [:test_p, :search_by_keyword, :search_by_dept]
	def test_p
	  page=params[:page].to_i
		id_begin=(page-1)*each_page_show
		@course_details=CourseDetail.where(:id=>id_begin..id_begin+each_page_show)
		#@course_details=@courses
		@page_numbers=CourseDetail.all.count/each_page_show
	  render "zz"
	end
  def index
		#prepare_course_db
	#@degree=['2','3']
	#destroy_course
	#prepare_course_db
	@semesters=Semester.all
	#@departments=Department.where(:degree=>'3')
	@departments2=Department.where(:degree=>'2')
	
	@department=Department.find(1)#.take(30)
	@courses=@department.courses.take(30)
	
	@departments=Department.where(:viewable=>'1')
	@departments_all_select=@departments.map{|d| {"walue"=>d.id, "label"=>d.ch_name}}.to_json
	@departments_grad_select=@departments.select{|d|d.degree=='2'}.map{|d| {"walue"=>d.id, "label"=>d.ch_name}}.to_json
	@departments_under_grad_select=@departments.select{|d|d.degree=='3'}.map{|d| {"walue"=>d.id, "label"=>d.ch_name}}.to_json
	@departments_common_select=@departments.select{|d|d.degree=='0'}.map{|d| {"walue"=>d.id, "label"=>d.ch_name}}.to_json
	
	@degree_select=[{"walue"=>'3', "label"=>"大學部[U]"},{"walue"=>'2', "label"=>"研究所[G]"},{"walue"=>'0', "label"=>"大學部共同課程[C]"}].to_json
	
	@semester_select=Semester.all.select{|s|s.courses.count>0}.map{|s| {"walue"=>s.id, "label"=>s.name}}.to_json
	
	
	
	
  end
	
	def search_by_dept
		dept_id=params[:dept_id]
		semester_id=params[:sem_id].to_i
		
		dept_ids=get_dept_ids(dept_id)
		
		semester=Semester.find(semester_id)
		@courses=semester.courses.select{|c| join_dept(c,dept_ids)}
		course_ids=@courses.map{|c| c.id}
		@course_details=CourseDetail.where(:course_id=>course_ids)
		@page_numbers=@course_details.count/each_page_show
		render "zz"
	end
	
	
  def rate_course
    course_id=params[:_course_id]
		score=params[:_score]
		Rating.create(:score=>score, :target_id=>course_id, :user_id=>current_user.id, :target_type=>"course")
		#total=Rating.where(
		result={:new_score=>'3'}
		respond_to do |format|
			format.html {
				render :json => result.to_json,
							 :content_type => 'text/html',
							 :layout => false
			}
		end
	end
  def search_by_keyword
	  search_term=params[:search_term]
		search_type=params[:search_type]
		semester_id=params[:sem_id].to_i
		dept_id=params[:dept_id]
		dept_ids= get_dept_ids(dept_id)
		case search_type
			when "course_no"
				if !semester_id.nil?
					@courses= Course.where(" id IN (:id) AND real_id LIKE :real_id ",
							{ :id=>SemesterCourseship.select("course_id").where(:semester_id=> semester_id), :real_id => "%#{search_term}%" })	
				else
					@courses= Course.where("real_id LIKE :real_id ",
																{:real_id => "%#{search_term}%" })#, :id=> SemesterCourseship.select("course_id").where(:semester_id=> "8"))		
				end
				@courses=@courses.select{|c| join_dept(c,dept_ids) } if dept_ids
				
			when "course_name"
				if !semester_id.nil?
					@courses = Course.where("id IN (:id) AND ch_name LIKE :name ",
						{:id=>SemesterCourseship.select("course_id").where(:semester_id=> semester_id), :name => "%#{search_term}%" })
				else
					@courses= Course.where("ch_name LIKE :name ",
																{:name => "%#{search_term}%" })#, :id=> SemesterCourseship.select("course_id").where(:semester_id=> "8"))		
				end
				@courses=@courses.select{|c| join_dept(c,dept_ids) } if dept_ids
		end
		course_ids=@courses.map{|c| c.id}
		@course_details=CourseDetail.where(:course_id=>course_ids)
		@page_numbers=@course_details.count/each_page_show
		render "zz"
	end
	# def search_by_keyword_ajax
    # search_term=params[:_search_term]
		# search_type=params[:_search_type]
		# semester_id=params[:_semester_id].to_i
		# dept_id=params[:_dept_id]
		
		# dept_ids= get_dept_ids(dept_id)
				
		# case search_type
			# when "course_no"
				# if !semester_id.nil?
					# @courses= Course.where(" id IN (:id) AND real_id LIKE :real_id ",
							# { :id=>SemesterCourseship.select("course_id").where(:semester_id=> semester_id), :real_id => "%#{search_term}%" })	
				# else
					# @courses= Course.where("real_id LIKE :real_id ",
																# {:real_id => "%#{search_term}%" })#, :id=> SemesterCourseship.select("course_id").where(:semester_id=> "8"))		
				# end
				# @courses=@courses.select{|c| join_dept(c,dept_ids) } if dept_ids
				
			# when "course_name"
				# if !semester_id.nil?
					# @courses = Course.where("id IN (:id) AND ch_name LIKE :name ",
						# {:id=>SemesterCourseship.select("course_id").where(:semester_id=> semester_id), :name => "%#{search_term}%" })
				# else
					# @courses= Course.where("ch_name LIKE :name ",
																# {:name => "%#{search_term}%" })#, :id=> SemesterCourseship.select("course_id").where(:semester_id=> "8"))		
				# end
				# @courses=@courses.select{|c| join_dept(c,dept_ids) } if dept_ids
		# end
		# respond_to do |format|
			# format.html {
				# render :json => @courses.map{|course|
														# course.course_details.flit_semester(semester_id).map{|cd|cd.to_result(course) }
												# },
					# :content_type => 'text/html',
					# :layout => false
			# }
		# end
  # end
	
  # def search_by_dept_ajax
		# dept_id=params[:_dept_id]
		# semester_id=params[:_semester_id].to_i
		
		# dept_ids=get_dept_ids(dept_id)
		
		# @semester=Semester.find(semester_id)
		# @courses=@semester.courses.select{|c| join_dept(c,dept_ids)}

		# respond_to do |format|
			# format.html {
				# render :json => @courses.map{|course|
														# course.course_details.flit_semester(semester_id).map{|cd|cd.to_result(course) }
												# },
					# :content_type => 'text/html',
					# :layout => false
			# }
		# end
	# end
	
  private
	def each_page_show
	  30
	end
	def get_dept_ids(dept_id)
	  return nil if dept_id==""
		
	  dept_ids=[]
		dept_main=Department.find(dept_id)
		dept_ids.append(dept_main.id)
		dept_college=Department.where("degree = #{dept_main.degree} AND viewable = '1' AND real_id LIKE :real_id",{:real_id=>"#{dept_main.college.real_id}%"}).take
		dept_ids.append(dept_college.id) if !dept_college.nil?
		return dept_ids
	end
	
	def join_dept(course,dept_ids)
		dept_ids.each do |dept_id|
		  return true if course.department_id==dept_id
		end
		return false
	end
	
  def change_to_grad_degree(real_id)
    @old=Department.where(:degree=>'3', :real_id=>real_id).take.id
	@new=Department.where(:degree=>'2', :real_id=>real_id).take.id
	Course.where(:department_id=>@old).each do |c|
	  c.update_attributes(:department_id=>@new)
	end
	Teacher.where(:department_id=>@old).each do |t|
	  t.update_attributes(:department_id=>@new)
	end
  end
  def set_department_viewable
    Department.all.each do |dept|
	  if dept.courses.count==0
	    dept.update_attribute(:viewable,'0')
	  else 
	    dept.update_attribute(:viewable,'1')
	  end
	end
  end
  def destroy_course
    Course.destroy_all
    Teacher.destroy_all
  end
  def save_sem_courseship(sem_id,course_id)
    #sem_id=Semester.find_by_real_id(sem_real_id).id
	unless SemesterCourseship.where(:semester_id=>sem_id,:course_id=>course_id).take
	  SemesterCourseship.create(:semester_id=>sem_id,:course_id=>course_id)
	end
  end
  def prepare_course_db
  
    year=['103']
		sem='1'
		year.each do |y|
			data=parse_course(y,sem)
			save_courses(data,y,sem)
			change_to_grad_degree("12")
			change_to_grad_degree("13")
			set_department_viewable
		end
  end
  def do_save_courses(sem_id,data)
    data.each do |key1,value1|
	#@html<<value1['cos_cname']<<value1['cos_ename']<<value1['teacher']<<"<br>"
	
	@dept=Department.find_by_real_id(value1['dep_id'])
	next if @dept.nil?
	dept_id=@dept.id
	
	teacher=save_teacher(value1['teacher'],dept_id)
	course=save_course(value1['cos_code'],value1['cos_cname'],value1['cos_ename'],dept_id)
	save_course_detail(teacher.id,course.id,sem_id,value1)
	save_sem_courseship(sem_id,course.id)
  end
  end
  def save_courses(data,year,sem)
    sem_id=Semester.find_by_real_id(year+sem).id
    data.each do |data1|
	  data1.each do |data2|#|key,value|
	    next if data2.empty?
	    data2.each do |key,value|
		  data3=value.fetch('1',[])
		  do_save_courses(sem_id,data3)
		  #data4=value.fetch('2',[])
		  #do_save_courses(sem_id,data4)		  
		end
	  end
	end
  end
  def parse_semester
    year=(98..103)
	semester=(1..2)
	name=['上','下']
	year.each do |y|
	  semester.each do |s|
	    sem=Semester.new(:real_id=>y.to_s+s.to_s)
		sem.name=y.to_s+name[s-1]
		sem.save
	  end
	end
  end
  def save_course_detail(teacher_id,course_id,sem_id,raw_data)
    @cd=CourseDetail.where(:teacher_id=>teacher_id,:course_id=>course_id, :semester_id=>sem_id).take
    if @cd.nil?
	  #@department
	  @cd=CourseDetail.new
		@cd.teacher_id=teacher_id
		@cd.course_id=course_id
		@cd.semester_id=sem_id
		@cd.credit=raw_data['cos_credit']
		@cd.time_and_room=raw_data['cos_time']
		@cd.memo=raw_data['memo']
		@cd.students_limit=raw_data['num_limit']
		@cd.cos_type=raw_data['cos_type']
		@cd.temp_cos_id=raw_data['cos_id']
		@cd.brief=raw_data['brief']
	  @cd.save
	  
	#else
	#  return nil
	end
	return @cts
  end
  def save_course(code,ch_name,eng_name,dept_id)
    @course=Course.find_by_real_id(code)
    if @course.nil?
	  #@department
	  @course=Course.new(:ch_name=>ch_name,:eng_name=>eng_name,:real_id=>code,:department_id=>dept_id)
	  @course.save
	  
	#else
	#  return nil
	end
	return @course
  end
  def save_teacher(name,dept_id)
    @teacher=Teacher.find_by_name(name)
    if @teacher.nil?
	  #@department
	  #dep_id=Department.find_by_real_id(real_id).id
	  
	  @teacher=Teacher.new(:name=>name,:department_id=>dept_id)
	  @teacher.save
	  
	#else
	#  return nil
	end
	return @teacher
  end
  
  def parse_course(year,sem)
    @dept_real_id=[]
	Department.all.each do |dept|
	@dept_real_id.append(dept.degree+dept.real_id)
	end
	
	@slice=21
	
	threads=[]
	(0..7).each do |i| 
	 threads<<Thread.new{Thread.current[:output] = get_course(@dept_real_id,i*@slice,@slice,year,sem)} 

	end 

	#@html=""

	data=[]
	threads.each do |t| 
	  t.join
	  data.append(t[:output])
	end
	return data
  end
  def parse_college
    @type=[3]
	
    data=Array.new
    @type.each do |_type|
	  @send={"ftype"=>_type,"fcategory"=>_type.to_s+'*',"flang" =>'zh-tw'}
	  http=Curl.post("http://timetable.nctu.edu.tw/?r=main/get_college",@send)
	  @college=JSON.parse(http.body_str.force_encoding("UTF-8"))
	  @college.each do |college|
		College.create(:name=>college['CollegeName'], :real_id=>college['CollegeNo'])
	  end
	  
	end
	return data
  end
  def parse_dep
    @type=[3,2,0]#,7,72,8] 
	
    data=Array.new
    @type.each do |_type|
	  @send={"ftype"=>_type,"flang" =>'zh-tw'}
	  http=Curl.post("http://timetable.nctu.edu.tw/?r=main/get_category",@send)
	  @category=JSON.parse(http.body_str.force_encoding("UTF-8"))
	  @category.each do |key,value|
		#@html<<value
	    College.all.each do |college|
		  @payload={"acysem"=>'1031', "ftype"=>_type,"fcategory"=>key,
		       "fcollege"=>college.real_id, "flang" =>'zh-tw'}
		  http=Curl.post("http://timetable.nctu.edu.tw/?r=main/get_dep",@payload)
		  
		  @result=JSON.parse(http.body_str.force_encoding("UTF-8"))
		  @result.each do |result1|
		    next if result1["unit_id"].nil?
		    next if Department.where(:degree=>result1['unit_id'][0], :real_id=>result1['unit_id'][1..2]).take
			department=Department.new
			department.degree=result1['unit_id'][0]
			department.real_id=result1['unit_id'][1..2]
			department.ch_name=result1['unit_name']
			department.college_id=college.id
			department.save!
		  end
		  #@result.college_id=college.id
		  #@result
		  #@result.merge({'college_id'=>college.id}.to_json)
		  #data.append(@result)		  
	    end
	  end
	end
	#Department.destroy_all(:degree=>'3', :real_id=>"11")
	#Department.destroy_all(:degree=>'3', :real_id=>"12")
	#Department.destroy_all(:degree=>'3', :real_id=>"13")
	#return data
  end
 
  def get_course(dept_real_id,begin_dep_id,num_to_get,year,sem)
	data=[]
	  (begin_dep_id..(begin_dep_id+num_to_get)).each do |index|
	    break if index>=dept_real_id.length
		dept_id=dept_real_id[index]#real_id
		#break if department.id>=50
		@payload = {"m_acy" => year, 'm_sem' => sem, 'm_degree'=>dept_id[0], 'm_dep_id'=>dept_id[1..2],'m_group'=>'**',
			'm_grade'=>'**','m_class'=>'**','m_option'=>'**','m_crsname'=>'**','m_teaname'=>'**','m_cos_id'=>'**',
			'm_cos_code'=>'**','m_crstime'=>'**','m_crsoutline'=>'**'}#.to_json
		http=Curl.post("http://timetable.nctu.edu.tw/?r=main/get_cos_list",@payload)
		
		@result=JSON.parse(http.body_str.force_encoding("UTF-8"))
		data.append(@result)
	  end
	#end
	return data
  end
	
  
end
