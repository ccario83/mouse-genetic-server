module ApplicationHelper
	
	# Return the full title on a per-page status.
	def full_title(page_title)
		base_title = 'Berndt Lab'
		if page_title.empty?
			base_title
		else
				"#{base_title} | #{page_title}"
		end
	end
	
	def color_tag(record)
		if record.class == User
			if record == current_user
				"<span class='display-You'>You</span>".html_safe
			else
				("<span class='display-User'>" + record.name + "</span>").html_safe
			end
		elsif record.class == Group
			("<span class='display-Group'>" + record.name + "</span>").html_safe
		end
	end
	
	def text_tag(record)
		if record.class == User
			if record == current_user
				"You".html_safe
			else
				record.name.to_s.html_safe
			end
		elsif record.class == Group
			record.name.to_s.html_safe
		end
	end
	
	def to_from_color_tag(to, from)
		tag = ""
		[to, from].each do |obj|
			if obj.length == 1
				if obj.class == User
					if obj == current_user
						tag = tag + "<span class='display-You'>you</span>"
					else
						tag = tag + "<span class='display-User'>" + obj.creator.name + "</span>"
					end
				elsif obj.class == Group
					tag = tag + "<span class='display-Group'>" + obj.name + "</span>"
				end
			else
				if obj.class == User
					if obj == current_user
						tag = tag + "<span class='display-User'>You and others</span>"
					else
						tag = tag + "<span class='display-User'>many people</span>"
					end
				elsif obj.class == Group
					tag = tag + "<span class='display-Group'>many groups</span>"
				end
			end
			tag = tag + ' to '
		end
		
		return tag.html_safe
	end
end
