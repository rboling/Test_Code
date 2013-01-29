# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  $("body").delegate ".answer_form_button", "click", ->

    $(this).closest(".question_item").find('.answer_form').css "display", "block"
    if $('.question_activity_list ul').height() < 600
      $(".course_activity .jspContainer").height($('.question_activity_list ul').height())
    else
      $(".course_activity .jspContainer").height(600)
    $('.question_activity_list').data('jsp').reinitialise()


  $("body").delegate ".answer_form .cancel", "click", ->
    $(this).closest(".answer_form").css "display", "none"
