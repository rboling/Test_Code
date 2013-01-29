class Recommendation < ActiveRecord::Base

  belongs_to :user
  belongs_to :school
  serialize :conn_cda, Hash
  serialize :rank_cda, Hash
  
  attr_accessible :conn_cda, :user_id, :school_id, :rank_cda
  
  def Recommendation.populate_rec_bar(current_user_id)
    return Recommendation.find_top_buddies(current_user_id, 6)
  end
  
  def Recommendation.initial_spawn(current_user_id)
    return Recommendation.find_by_user_id(current_user_id).nil?
  end
  
  #call this when creating a new user; maybe also run it initially because of existing db users without a rec attached
  def Recommendation.populate_user(all_users_ids)
    all_users_ids.each do |curr_user_id|
      #generate hash of first 10000 user_ids with ranks initialized to 0, except for curr_user, which is set to 20
      #TODO problems arise if somebody changes school!!!
      arrA = User.where( :school_id => User.find(curr_user_id).school_id ).map(&:id)
      arrB = [0]*arrA.size
      conns = Hash[arrA.zip arrB]
      arrB = [[0,0]]*arrA.size
      ranks = Hash[arrA.zip arrB]
     # if cui/10 <= 10000
     #   rankings[cui/10] = 20
     # end
      @curr_user = User.find(curr_user_id)
      if !@curr_user.recommendations.empty?
        @curr_user.recommendations.delete_all
      end
      @new_rec = Recommendation.new(:user_id => curr_user_id, :school_id => User.find_by_id(curr_user_id).school.id, :conn_cda => conns, :rank_cda => ranks)
      @new_rec.save!
    end
  end
  
  def Recommendation.find_top_buddies(cur_userid,limit)
    ids = []
    ranks = []
    #Convert user ids (i.e id user id is 41, mapped id will be 4)
    #cur_userid = cur_userid/10
    rank_hash = Recommendation.find_by_user_id(cur_userid).rank_cda
  #  if rank_hash.empty? then return [41,51,8981] end
    rank_arr = []
    rank_hash.each do |k,v|
      rank_arr += [[k,v[0]]]
    end
    sorted_rank_arr = rank_arr.sort{|a,b| a[1] <=> b[1]}
    user1 = User.find(cur_userid)
    
    while (limit > 0 and sorted_rank_arr.size > 0)
      pair = sorted_rank_arr.pop
      user2 = User.find_by_id(pair[0]) 
      if user2     
        if !(user1.friend_with?user2) and (cur_userid != pair[0])
          ids << pair[0]
          ranks << pair[1]
          limit -= 1
        end
      end
    end
    if !ranks.empty? 
      sum = ranks.inject{|sum,x| sum + x }
      if sum <= 0
      #  return [41,51,8981]
        ross = User.find(41)
        ben = User.find(51)
        if user1.friend_with? ben or user1.invited? ben or ben.invited user1 and user1.friend_with? ross or user1.invited? ross or ross.invited user1
          return []
        elsif user1.friend_with? ben or user1.invited? ben or ben.invited user1
          return [41]
        elsif user1.friend_with? ross or user1.invited? ross or ross.invited user1
          return [51]
        else
          return [51,41]
        end
      else
        return ids
      end
    else
      ross = User.find(41)
      ben = User.find(51)
      if user1.friend_with? ben or user1.invited? ben or ben.invited user1 and user1.friend_with? ross or user1.invited? ross or ross.invited user1
        return []
      elsif user1.friend_with? ben or user1.invited? ben or ben.invited user1
        return [41]
      elsif user1.friend_with? ross or user1.invited? ross or ross.invited user1
        return [51]
      else
        return [51,41]
      end
    end
  end
  #This finds the rank of user2id in cur_userid's recommendation list out of scale. Thus if scale is 5, then a ranking of 4 indicates that user2 is in the top 40% of matches for cur_user.
  def Recommendation.find_scaled_rank(cur_userid,user2id,scale)
    #Convert user ids (i.e id user id is 41, mapped id will be 4)
    #cur_userid = cur_userid/10
    #user2id = user2id/10 
    rank_hash = Recommendation.find_by_user_id(cur_userid).rank_cda
    rank_of_user2 = rank_hash[user2id][0]
   # if rank_of_user2.nil? and [41,51,8681].include?(user2id)
    if rank_of_user2.nil? 
      if [41,51].include?(user2id)
        return 10
      else
        return 0.5
      end  
    end 
    rank_arr = []
    rank_hash.each do |k,v|
      rank_arr += [[k,v[0]]]
    end
    sorted_rank_arr = rank_arr.sort{|a,b| a[1] <=> b[1]}
    ranks = []
    sorted_rank_arr.each do |a,b|
      ranks << b
    end
    x = rank_hash.size/(2**(scale) - 1) == 0 ? 1: rank_hash.size/(2**(scale) - 1)
    absolute_rank = ranks.find_index(rank_of_user2)
    flow = (absolute_rank/x) < 1 ? 1: (absolute_rank/x)
    Math.log(flow,2) + 1.5
  end
  def Recommendation.connect_new(user1id, user2id, inc)
    user1_ranking = Recommendation.find_by_user_id(user1id)
    user2_ranking = Recommendation.find_by_user_id(user2id)
    user1_ranking.rank_cda[user2id] =  [user1_ranking.rank_cda[user2id][0] + inc,user1_ranking.rank_cda[user2id][1] + inc]
    user1_ranking.save!
    user2_ranking.rank_cda[user1id] = [user2_ranking.rank_cda[user1id][0] + inc, user2_ranking.rank_cda[user1id][1] + inc]
    user2_ranking.save!
  end
  def Recommendation.disconnect_new(user1id, user2id, inc)
    debugger
    user1_ranking = Recommendation.find_by_user_id(user1id)
    user2_ranking = Recommendation.find_by_user_id(user2id)
    user1_ranking.rank_cda[user2id] =  [user1_ranking.rank_cda[user2id][0] - inc,user1_ranking.rank_cda[user2id][1] - inc]
    user1_ranking.save!
    user2_ranking.rank_cda[user1id] = [user2_ranking.rank_cda[user1id][0] - inc, user2_ranking.rank_cda[user1id][1] - inc]
    user2_ranking.save!
  end
  #This updates the connections between users in a friendship
  def Recommendation.fconnect_new(user1id, user2id, inc)
    if User.find(user1id).school_id == User.find(user2id).school_id
    #convert user ids
    #user1id = user1id/10
    #user2id = user2id/10 
    #find rankings an update rank for each user by inc
      if Recommendation.find_by_user_id(user1id).nil?
        Recommendation.populate_user([user1id])
      end
      user1_ranking = Recommendation.find_by_user_id(user1id)
      user1_ranking.conn_cda[user2id] += inc
      user1_ranking.save!
      if Recommendation.find_by_user_id(user2id).nil?
        Recommendation.populate_user([user2id])
      end
      user2_ranking = Recommendation.find_by_user_id(user2id)
      user2_ranking.conn_cda[user1id] += inc
      user2_ranking.save!
    end
    return true
  end
  
  #decrement connection
  def Recommendation.fdisconnect_new(user1id, user2id, inc)
    if User.find(user1id).school_id == User.find(user2id).school_id
    #convert user ids
    #user1id = user1id/10
    #user2id = user2id/10 
    #find rankings an update rank for each user by inc
      user1_ranking = Recommendation.find_by_user_id(user1id)
      user1_ranking.conn_cda[user2id] -= inc
      if user1_ranking.conn_cda[user2id] < 0
        user1_ranking.conn_cda[user2id] = 0
      end
      user1_ranking.save!
      user2_ranking = Recommendation.find_by_user_id(user2id)
      user2_ranking.conn_cda[user1id] -= inc
      if user2_ranking.conn_cda[user1id] < 0
        user2_ranking.conn_cda[user1id] = 0
      end
      user2_ranking.save!
    end
    return true
  end
  
  #This computes the dot product of the values of two hashes (ranking1, ranking2)
  def Recommendation.norm_dot_product(ranking1, ranking2)
    l1 = ranking1.to_a.sort.map{|ele| ele[1]}
    l2 = ranking2.to_a.sort.map{|ele| ele[1]}
	  sum = 0.0
	  normer = 0.0
	  l1.zip(l2) do |a, b| 
	    sum+=a*b
	    normer+= a**2 + b**2
    end
	  return sum/(normer**(1/2))
  end
  
  def Recommendation.list_all
    schools = School.all
    schools.each do |school|
      Rails.logger.info("Logging #{school.name} now.")
      Recommendation.generate_ranked_list(school.id)
    end
  end
  def Recommendation.generate_ranked_list(schoolID)
    school_recs = Recommendation.where(:school_id => schoolID)
    #For each Recommendation in the school_recs list
    school_recs.each do |rec|
      #instantiate empty hash for rank_cda for the Recommendation
      rank_hash = Hash.new
      user_ranking = rec.conn_cda
      user_ranking.each do |userid,rank|
      id = rec.user_id
        #find dot product of the two rankings
        if !Recommendation.find_by_user_id(userid).nil?
          if rec.user_id != userid
            other_ranking = Recommendation.find_by_user_id(userid).conn_cda
            result = Recommendation.norm_dot_product(user_ranking,other_ranking)
          else
            result = 0
          end
        else
          result = 0
        end
        #update the rank_hash for current user
        rank_hash[userid] = [result+rec.rank_cda[userid][1],rec.rank_cda[userid][1]]
      end
      rec.rank_cda
      #update the Recommendation
      rec.update_attributes(:rank_cda => rank_hash)
    end  
    return true
  end
=begin
  #also BIGGGGG method - only run intermittently to update Indices for everybody in a particular school
  def Recommendation.generate_ranked_list(schoolID)
    #fetch the school recs and generate empty arrays
    school_collect = Recommendation.where(:school_id => schoolID)
    schoolMatrix = []
    userIDS = []
    user_recs = []
    
    #grab the connections string and move it into a few arrays
    school_collect.each do |rec|
      #split the cda
      userCDA = rec.conn_cda.split(',')
      #write string to int
      userCDA = userCDA.collect{|i| i.to_i}
      #throw it into bigger array
      schoolMatrix << userCDA
      #nx1 array
      userIDS << rec.user_id
    end
    
    #use this as an iterator for writing to the db
    userid = 0
    
    #through the school matrix once
    schoolMatrix.each do |uid1|
      user_recs_final = []
      recs_temp = []
      
      #through the school matrix twice - note this will always rank the user first in his own list, so this needs to be processed out later
      schoolMatrix.each do |uid2|
        #normalize the dot product and push it to the array of listings
        recs_temp << Recommendation.norm_dot_product(uid1, uid2)
      end
      
      rtl = recs_temp.length
      #iterate through for each member of the array, this will work since index only returns the last of the max
      rtl.times do
        #use rindex because the last added member with the best linkage (ie not time based but more recent links) probably better match
        max_index = recs_temp.rindex(recs_temp.max)
        user_recs_final << userIDS[max_index]
        #set this element to a negative number so that next iteration we find second largest and so forth
        recs_temp[max_index] = -1
      end
      
      #push comma delimited string of complete rankings based upon user id for each student at this school
      @temp_rec = Recommendation.find_by_user_id(userIDS[userid])
      user_recs_final += [-1]
      user_recs_final.shift
      user_recs_string = user_recs_final.join(',')
      @temp_rec.update_attributes(:rank_cda => user_recs_string)
      
      #increment the iterator
      userid += 1
      #ruby wants it??
      use = uid1
    end
    return true
  end 
  #called by svd method
  def Recommendation.school_matrix(schoolID)
    school_collect = Recommendation.where(:school_id => schoolID)
    schoolMatrix = []
    userIDS = []
    school_collect.each do |rec|
      userCDA = rec.conn_cda.split(',')
      userCDA = userCDA.collect{|i| i.to_i}
      schoolMatrix << userCDA
      userIDS << rec.user_id
    end
    return userIDS, Linalg::DMatrix.rows(schoolMatrix)
  end
  
  #BIGGGGG method - only run intermittently to update Indices
  def Recommendation.svd(schoolID)
  
    userIDS, conn_matrix = Recommendation.school_matrix(schoolID)
  
    #do the svd
    u,s,v = conn_matrix.singular_value_decomposition
    vt = v.transpose
    
    #reduce to 10 space to get n x 10 matrices and 10 singular values
    u10 = Linalg::DMatrix.join_columns[u.column(0),u.column(1),u.column(2),u.column(3),u.column(4),u.column(5),u.column(6),u.column(7),u.column(8),u.column(9)]
    vt10 = Linalg::DMatrix.join_columns[vt.column(0),vt.column(1),vt.column(2),vt.column(3),vt.column(4),vt.column(5),vt.column(6),vt.column(7),vt.column(8),v.column(9)]
    s10 = Linalg::DMatrix.join_columns[s.column(0).to_a.flatten[0,10],s.column(1).to_a.flatten[0,10],s.column(2).to_a.flatten[0,10],s.column(3).to_a.flatten[0,10],s.column(4).to_a.flatten[0,10],s.column(5).to_a.flatten[0,10],s.column(6).to_a.flatten[0,10],s.column(7).to_a.flatten[0,10],s.column(8).to_a.flatten[0,10],s.column(9).to_a.flatten[0,10]]
    
    #now put this into strings and write to db for each user
    j = 0
    
    userIDS.each do |id|
      @rec_user = Recommendation.find(:user_id => id)
      u10string = u10.row(j).join(',')
      vt10string = vt10.row(j).join(',')
      @rec_user.update_attributes(:u_svd10 => u10string, :vt_svd10 => vt10string)
      j++
    end
    
    # we also need to update the singular values for the school
    eig_string = ''
    
    s10.rows.each do |r|
      eig_string += r.join(',') + ';'
    end
    
    School.find(:id => schoolID).update_attributes(:s_svd10 => s10)
    
    return true
        
  end
=end
  
end
