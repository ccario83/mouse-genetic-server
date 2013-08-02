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
		tag = ""
		record = record[0] if record.is_a? Array and record.length == 1
		if record.is_a? Array
			if record[0].class == User
				if record == current_user
					tag = tag + "<span class='display-User'>You and others</span>"
				else
					tag = tag + "<span class='display-User'>Many people</span>"
				end
			elsif record[0].class == Group
				tag = tag + "<span class='display-Group'>Many groups</span>"
			end
		else
			if record.class == User
				if record == current_user
					tag = tag + "<span class='display-You'>You</span>"
				else
					tag = tag + "<span class='display-User'>" + record.name + "</span>"
				end
			elsif record.class == Group
				tag = tag + "<span class='display-Group'>" + record.name + "</span>"
			end
		end
		return tag.html_safe
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
	
	def to_from_color_tag(from, to)
		tag = ""
		[from, to].each_with_index do |obj, index|
			tag = tag + color_tag(obj)
			tag = index == 0? tag + ' to ' : tag
		end
		return tag.html_safe
	end
end
