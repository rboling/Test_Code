#$ ->
#  $("body").delegate "#question_form_button, #new_class_question, #filter_questions_form, .answer_form", #"ajax:success", (evt, data, status, xhr) ->
#    $("#filter_questions_button").popover("hide")
#    $("#class_share_button").popover("hide")
#    pane_api = $('.course_activity_list').data('jsp')
#    pane_api.getContentPane().html(xhr.responseText)
#    if $('.question_activity_list ul').height() < 600
#      $(".question_activity .jspContainer").height($('.question_activity_list ul').height())
#    else
#      $(".course_activity .jspContainer").height(600)
#    pane_api.reinitialise()
