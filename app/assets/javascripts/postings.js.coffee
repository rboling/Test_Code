# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  $("body").delegate ".posting_form_button", "click", ->
    $(this).closest(".question_item").find('.posting_form').css "display", "block"
    alert("post")
    if $('.course_activity ul').height() < 550
      $(".course_activity .jspContainer").height($('.course_activity ul').height())
    else
      $(".course_activity .jspContainer").height(550)
    $('.course_activity').data('jsp').reinitialise()
  
  $("body").delegate ".posting_form .cancel", "click", ->
    $(this).closest(".posting_form").css "display", "none"
