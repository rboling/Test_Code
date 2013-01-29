<% puts "honky tonk woman" %>
$("#user_activity").html('<%= link_to "Your Activity <small>(#{current_user.activity.count})</small>".html_safe, '#activities_tab' %>');
$("#activity_here").html('<%=j render partial: 'users/list_item' %>');
$("#activity_form").reset();
