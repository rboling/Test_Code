# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  $(".masonry_container").masonry
    itemSelector: "masonry_item",
    columnWidth : 150
  
  $("body").delegate ".add_course_final", "ajax:success", (evt, data, status, xhr) ->
    $(".popover").remove()
    $('.course_list').html xhr.responseText
    $('.course_list').append("<li class='add'><a id='add_course_button' href='#' data-original-title=''><span>Add a course</span></a></li>")
  
  $(".alert .close").click ->
    $(".alert").css "display", "none"
jQuery ->
  if $('.pagination').length
    $(window).scroll ->
      url = $('.pagination .next_page').attr('href')
      if url && $(window).scrollTop() > $(document).height() - $(window).height() - 50
        $('.pagination').text("Fetching more activity...")
        $.getScript(url)
    $(window).scroll()
  
  #  $('#activitytext').css "width", "400px"
  #  $('#activitytext').css "height", "100px"
  #  $('#activitytext').css "background-color", "#FFFFFF"    
#  $("#activity_message").click -> 
   # $('#activitytext').css "background-color", "#D3D3D3"
#    $('#activitytext').css "width", "400px"
#    $('#activitytext').css "height", "50px"
#    $(".final").css "display", "none"

 # $("#dummy-main").click ->
 #   $(".final").css "display", "none"
 #   $('#activitytext').css "width", "400px"
 #   $('#activitytext').css "height", "50px"
   # $('#activitytext').css "background-color", "#D3D3D3"

  # $(".sidebar").click ->
  #  $(".final").css "display", "none"
  #  $('#activitytext').css "width", "400px"
  #  $('#activitytext').css "height", "50px"
  #  $('#activitytext').css "background-color", "#D3D3D3"




  

    
  #$("#dummy-maine").click ->
  #  $(".final").css "display", "none"
  #  $('#activitytext').css "width", "400px"
  #  $('#activitytext').css "height", "50px"
   # $('#activitytext').css "background-color", "#D3D3D3"

 # $("#dummy-mained").click ->
  #  $(".final").css "display", "none"
  #  $('#activitytext').css "width", "400px"
  #  $('#activitytext').css "height", "50px"
   # $('#activitytext').css "background-color", "#D3D3D3"

 # $("#dummy-mainee").click ->
   # $(".final").css "display", "none"
   # $('#activitytext').css "width", "400px"
   # $('#activitytext').css "height", "50px"
   # $('#activitytext').css "background-color", "#D3D3D3"

#  $("#activity_here").click ->
   # $(".final").css "display", "none"
   # $('#activitytext').css "width", "400px"
   # $('#activitytext').css "height", "50px"
   # $('#activitytext').css "background-color", "#D3D3D3"


 # $("#dummy_clicker").click ->
   # $(".final").css "display", "none"
   # $('#activitytext').css "width", "400px"
   # $('#activitytext').css "height", "50px"
   # $('#activitytext').css "background-color", "#D3D3D3"

 # $("#do_this_right").click ->
 #   $(".final").css "display", "none"
 #   $('#activitytext').css "width", "400px"
 #   $('#activitytext').css "height", "50px"
   # $('#activitytext').css "background-color", "#D3D3D3"


  $("body").delegate " .activity_message", "mouseover", ->
    $message = $(this)
    $reply_section = $(this).find("#reply-section")
    $close_button = $(this).find("#close_button")
    $reply_section = $(this).find('#reply-section')
    $reply_form = $(this).find('#reply_form')
    $reply_button = $(this).find('#reply_button')
    $like_button = $(this).find('#like-section')
    $share_button = $(this).find('#share-section')
    $time_section = $(this).find('.time')
    $other_time_section = $(this).find('#other-time')
    if (($close_button.css "display") == 'none')
     # $message.css "height", "200px"
     # $like_box = $(this).find('#like-section')
     # $like_box.css "display", "inline"
     # $share_box = $(this).find('#share-section')
     # $share_box.css "display", "inline"
     # $delete_box = $(this).find('#delete_activity_section')
     # $delete_box.css "display", "inline"    
     # $delete_activity_box = $(this).find('#delete_activity_section_two')
     # $delete_activity_box.css "display", "inline"
     # $reply_button = $(this).find('#reply_button')
     # $reply_button.css "display", "inline-block"
      $reply_button.click -> 
        $message.css "height", "200px"
       # $time_section.css "display", "none"
        $reply_form.css "display", "inline"
        if ($other_time_section.text().length > 16)
          $other_time_section.css "margin-right", "44px"
        $reply_button.css "display", "none"
        $like_button.css "margin-top", "-30px"
        $share_button.css "margin-top", "-18px"
        $close_button.css "display", "inline-block"

       # $other_time_section.css "display", "inline-block"           
    else  
      $close_button.click ->
        $reply_form.css "display", "none"
        $reply_button.css "display", "inline-block"
        $like_button.css "margin-top", "-32px"
        $share_button.css "margin-top", "-18px"
       # $time_section.css "display", "inline-block"
        $message.css "height", "80px"

        $other_time_section.css "margin-right", "53px"
       # $reply_section.css "margin-left", "3px"

       # $other_time_section.css "display", "none"           

  $("body").on 'click', '#reply_button', (e) ->
     # $("body").trigger('reinit')
      e.preventDefault()
      e.stopPropagation()

  $("body").on 'click', '#close_button', (e) ->
     # $("body").trigger('reinit')
      e.preventDefault()
      e.stopPropagation()





        
  #  $reply_form = $(this).find('#reply_form')
  #  $reply_form.css "display", "inline"


 
  $("body").delegate " #activitytext", "keydown", ->
    if $(this).val().length == 110
      $("#activity_message").addClass('disabled')
      $("#text_warning").css "display", "inline"

  $("body").delegate " #activitytext", "keyup", ->
    if $(this).val().length == 110
      $("#activity_message").addClass('disabled')
      $("#text_warning").css "display", "inline"

  $("body").delegate " #activitytext", "keydown", ->
    if $(this).val().length < 110
      $("#activity_message").removeClass('disabled')
      $("#text_warning").css "display", "none"

  $("body").delegate " #activitytext", "keyup", ->
    if $(this).val().length < 110
      $("#activity_message").removeClass('disabled')
      $("#text_warning").css "display", "none"



  $("body").delegate " .activity_message", "mouseout", ->
    $message = $(this)

    $reply_section = $(this).find("#reply-section")

    $reply_button = $(this).find('#reply_button')
    $reply_form = $(this).find('#reply_form')
    $close_button = $(this).find("#close_button")
    $like_button = $(this).find('#like-section')
    $share_button = $(this).find('#share-section')
    $time_section = $(this).find('.time')
    $other_time_section = $(this).find('#other-time')
   # alert(($reply_form.css "display") == 'none')
    if ((($reply_form.css "display") == 'none'))
     # alert($reply_form.css "display")
      $message.css "height", "80px"
     # $like_box = $(this).find('#like-section')
     # $like_box.css "display", "none"
     # $share_box = $(this).find('#share-section')
     # $share_box.css "display", "none"
     # $delete_box = $(this).find('#delete_activity_section')
     # $delete_box.css "display", "none" 
     # $delete_activity_box = $(this).find('#delete_activity_section_two')
     # $delete_activity_box.css "display", "none"
     # $reply_button = $(this).find('#reply_button')
     # $reply_button.css "display", "none"
     # $reply_form = $(this).find('#reply_form')
    else
      $close_button.click ->
        $close_button.css "display", "none"
        $reply_form.css "display", "none"
        $reply_button.css "display", "inline-block"
        $message.css "height", "80px"
        $like_button.css "margin-top", "-30px"
        $share_button.css "margin-top", "-18px"
        $other_time_section.css "margin-right", "53px"
       # $reply_section.css "margin-left", "3px" 
       # $time_section.css "display", "inline-block"






      
   # alert('where am I dude')
    #  $reply_form.css "display", "none"
   # $reply_form.css "display", "none"






#  $("body").delegate " .home-header", "click", ->
#    $(".popover").css "display", "none"


#  $("body").delegate " .main-content", "click", ->
#    $(".popover").css "display", "none"


  $("body").delegate " .home-header", "click", ->
    $("#notifications_link_id").popover("hide")

  $("body").delegate " .main-content", "click", ->
    $("#notifications_link_id").popover("hide")




#  $(" .home_header").click ->
#    alert("hell yeah")
#    $("#notifications_link_id").popover.addClass("hide")


 # $("body").delegate " #like-section", "mouseover", ->
 #   $like_box_it = $(this).find('#likenumber')
 #   $like_box_it.css "display", "inline"

 # $("body").delegate " #like-section", "mouseout", ->
 #   $like_box_it = $(this).find('#likenumber')
 #   $like_box_it.css "display", "none"  

  $(".tabs li a").click ->
    $(".tabs li").removeClass('active')
    $(this).parent().addClass('active')
  $('#user_activity').click ->
    $("#news_tab").removeClass('active')
    $("#activities_tab").addClass('active')
    $("#activity_here").css "display", "block"
    $("#activity_form_home").css "display", "block"

  $('#news_link').click ->
    $("#activities_tab").removeClass('active')
    $("#news_tab").addClass('active')
    $("#activity_here").css "display", "none"
    $("#activity_form_home").css "display", "none"

  $(" .tabs").on 'click', '#user_activity, #news_link', (e) ->
      $(" .tabs").trigger('reinit')
      e.preventDefault()
 # $(window).scroll -> 
 #   position_height = $(".courses").position().top
   # position_height = $(".links-holder").position().top
    #alert('position height')
    #alert(position_height)
    #alert('scroll top')
    #alert($(window).scrollTop())
 #   if(position_height <= $(window).scrollTop())
 #     $("#invite_buddies_box").css "display", "none"
 #     $('.course_list').css "position", "fixed" 
 #     $(".home-header").css "position", "fixed" 
 #     $(".yr-buddies").css "position", "fixed" 
 #     $(".rec-buddies").css "position", "fixed" 
 #     $(".course_list").css "margin-left", "-4px"
 #     $(".course_list").css "margin-right", "-12px" 
 #     $(".course_list").css "width", "232px"
 #     $(".course_list").css "margin-top", "140px"
 #     $(".links-holder").css "margin-top", "-141px"  
 #     $(".links-holder").css "margin-left", "-7px"
     # $("#home_tabs").css "margin-left", "-108px"    
 #     $("#home_tabs").css "margin-left", "-300px"                                       
 #     $(".rec-buddies").css "margin-top", "347px"
 #     $(".yr-buddies").css "margin-top", "118px" 
 #     $(".yr-buddies").css "margin-right", "7px"  
     # $(".yr-buddies").css "margin-left", "173px" 
  #    $(".yr-buddies").css "margin-left", "-3px"   
  #    $(".yr-buddies").css "width", "-1px" 
  #    $(".yr-buddies").css "height", "0px"
  #    $(".yr-groups").css "position", "fixed"
  #    $(".yr-groups").css "margin-left", "202px"
  #    $(".yr-groups").css "margin-top", "395px"
  #    $(".rec-buddies").css "margin-top", "342px" 
  #    $(".rec-buddies").css "margin-left", "2px"  
  #    $(".rec-buddies").css "width", "205px"  
  #    $(".sidebar").css "margin-top", "1px"
  #    $("#god_bless_you_please_mrs_robinson").css "margin-right", "-354px"
  #    $("#god_bless_you_please_mrs_robinson").css "margin-top", "-189px"
                                                                                  
 #     $('.course_list').css "margin-top", "123px" 
 #     $(".home-header").css "margin-top", "-154px"
      $(".user_greeting").css "display", "none"  
      $("#home_tabs").css "width", "150px"
  #  else 
  #    $("#invite_buddies_box").css "display", "block"
  #    $('.course_list').css "position", "relative"
  #    $('.course_list').css "margin-top", "0px" 
  #    $(".home-header").css "position", "relative" 
  #    $(".yr-buddies").css "position", "relative" 
  #    $(".rec-buddies").css "position", "relative"
 #     $(".rec-buddies").css "margin-top", "0px"
 #     $(".yr-buddies").css "margin-top", "0px" 
 #     $(".home-header").css "margin-top", "0px"  
  #    $(".user_greeting").css "display", "inline-block"  
  #    $(".yr-groups").css "position", "relative"
  #    $(".course_list").css "margin-left", "1"
  #    $(".course_list").css "margin-right", "1" 
  #    $(".course_list").css "width", "250px"
  #    $(".links-holder").css "margin-top", "22px"  
  #    $(".links-holder").css "margin-left", "1"
  #    $("#home_tabs").css "margin-left", "-301px"  
  #    $("#home_tabs").css "margin-top", "-257px"     
  #    $("#home_tabs").css "width", "500px"
  #    $(".yr-buddies").css "margin-top", "-10px" 
  #    $(".yr-buddies").css "margin-right", "7px"  
  #    $(".yr-buddies").css "margin-left", "7px"  
  #    $(".yr-buddies").css "width", "205px" 
  #    $(".yr-buddies").css "height", "190px"
  #    $(".yr-groups").css "position", "relative"
  #    $(".yr-groups").css "margin-left", "1"
   #   $(".yr-groups").css "margin-top", "49px"
   #   $(".yr-groups").css "width", "205px"
   #   $(".rec-buddies").css "margin-top", "25px" 
   #   $(".rec-buddies").css "margin-left", "1px" 
   #   $(".rec-buddies").css "height", "200px"   
   #   $(".rec-buddies").css "width", "205px"  
   #   $("#god_bless_you_please_mrs_robinson").css "margin-right", "25px"
   #   $("#god_bless_you_please_mrs_robinson").css "margin-top", "0px"
   #   $("#god_bless_you_please_mrs_robinson").css "margin-left", "408px"
   #   $("#god_bless_you_please_mrs_robinson").css "float", "none"
     # $(".sidebar").css "margin-top", "-99px"
                                                                      

            
    


    
    

 






# $('#home_tabs').tabs()
# $('#home_tabs').bind(
#   'change',
#     (e)->
#       alert('foofoofoo')
#       $('#home_tabs').removeClass('active')
#       $($(e.target).attr('href')).addClass('active')
#    )
  
