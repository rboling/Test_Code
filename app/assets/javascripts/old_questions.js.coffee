# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  $("body").delegate "#question_form_button, #question_form, #new_class_question, #filter_questions_form, #answer_form, .answer_form", "ajax:success", (evt, data, status, xhr) ->
    $("#filter_questions_button").popover("hide")
    $("#class_share_button").popover("hide")
    $('.question_activity_list').jScrollPane()
    $('.question_activity_list').data('jsp').getContentPane().html(xhr.responseText)
    #if $('.question_activity_list ul').height() < 600
    #  $(".question_activity .jspContainer").height($('.question_activity_list ul').height())
    #else
    $(".course_activity .jspContainer").height(600)
    $('.question_activity_list').data('jsp').reinitialise()
