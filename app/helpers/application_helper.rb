module ApplicationHelper
  
  #def link_to_add_fields(name, f, association)
  #    new_object = f.object.send(association).klass.new
  #    id = new_object.object_id
  #    fields = f.fields_for(association, new_object, child_index: id) do |builder|
  #      render(association.to_s.singularize + "_fields", f: builder)
  #    end
  #    link_to(name, '#', class: "add_fields", data: {id: id, fields: fields.gsub("\n", "")})
  #end
   
   
  def clippy(text, bgcolor='#FFFFFF')
    html = <<-EOF
      <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"
              width="110"
              height="14"
              id="clippy" >
      <param name="movie" value="/clippy.swf"/>
      <param name="allowScriptAccess" value="always" />
      <param name="quality" value="high" />
      <param name="scale" value="noscale" />
      <param NAME="FlashVars" value="text=#{text}">
      <param name="bgcolor" value="#{bgcolor}">
      <embed src="/clippy.swf"
             width="110"
             height="14"
             name="clippy"
             quality="high"
             allowScriptAccess="always"
             type="application/x-shockwave-flash"
             pluginspage="http://www.macromedia.com/go/getflashplayer"
             FlashVars="text=#{text}"
             bgcolor="#{bgcolor}"
      />
      </object>.
    EOF
  end
  
  def items_layout
    params[:layout].presence || 'grid'
  end
  
  def logged_in?
    @current_user
  end

  def inbox_count
    count = current_user.all_messages({:deleted => false}).select {|m| !message_opened?(m)}.count
    
    case count
    when count > 99
      "*"
    when 0
      ""
    else
      count
    end
  end
  
  def controller?(*controller)
    controller.include?(params[:controller])
  end

  def action?(*action)
    action.include?(params[:action])
  end
  
  def inbox_class
      inbox_count > 0 ? 'no_messages' : 'messages'
  end

  def activate(active_key, key)
    active_key == key ? " active" : ""
  end

  def custom_url(user)
    "www.studyhall.com/" + user.custom_url
  end
   
  def user_missing
    "No Longer A User"
  end

  def ga_tag
    "<script type='text/javascript'>
        var _gaq = _gaq || [];
        _gaq.push(['_setAccount', 'UA-30973779-1']);
        _gaq.push(['_trackPageview']);
    
        (function() {
          var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
          ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
          var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
        })();
    
      </script>".html_safe
  end

  def typekit_loader_tag
    "<script type='text/javascript'>
      TypekitConfig = {
        kitId: '#{TYPEKIT_ID}'
      };
      (function() {
        var tk = document.createElement('script');
        tk.src = '//use.typekit.com/' + TypekitConfig.kitId + '.js';
        tk.type = 'text/javascript';
        tk.async = 'true';
        tk.onload = tk.onreadystatechange = function() {
          var rs = this.readyState;
          if (rs && rs != 'complete' && rs != 'loaded') return;
          try { Typekit.load(TypekitConfig); } catch (e) {}
        };
        var s = document.getElementsByTagName('script')[0];
        s.parentNode.insertBefore(tk, s);
      })();
    </script>".html_safe
  end
  
  def link_to_add_fields(name, f, association)
      new_object = f.object.send(association).klass.new
      id = new_object.object_id
      fields = f.fields_for(association, new_object, child_index: id) do |builder|
        render(association.to_s.singularize + "_fields", f: builder)
      end
      link_to(name, '#', class: "add_fields", data: {id: id, fields: fields.gsub("\n", "")})
  end
  
end
