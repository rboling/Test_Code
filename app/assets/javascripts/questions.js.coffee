# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->  
  $("body").delegate "#question_form_button, #question_only_button, #comment_only_button, #view_all_button, #new_class_question, #filter_questions_form, .answer_form, .posting_form", "ajax:success", (evt, data, status, xhr) ->
    $('.course_activity').jScrollPane()
    $('.question_activity_list').data('jsp').getContentPane().html(xhr.responseText)
    if $('.course_activity ul').height() < 550
      $(".course_activity .jspContainer").height($('.course_activity ul').height())
    else
      $(".course_activity .jspContainer").height(550)
    $('.course_activity').data('jsp').reinitialise()
