require "csv"
require "google/apis/civicinfo_v2"
require "erb"
require "date"

$dt_array = []

def clean_zipcode(zipcode)
	zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_phone_number(phone_number)
	begin
	if phone_number.length == 11
		if phone_number[0] == "1"
			phone_number[1..10]
		else
			raise
		end
	elsif phone_number.length == 10
		phone_number
	else
		raise
	end
	rescue
		"Incorrect phone number layout."
	end
end

def avg_hour_signup(date)
	$dt_array << (DateTime.strptime(date, "%m/%d/%y %k:%M")).strftime("%H").to_i
end

#same purpose as the avg_hour_signup
def avg_day_signup(date)
	#calculate avg day which people sign up on.
end

def legislators_by_zipcode(zip)
	civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
	civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"

	begin
		legislators = civic_info.representative_info_by_address(
															address: zip,
															levels: "country",
															roles: ["legislatorUpperBody", "legislatorLowerBody"]).officials

	rescue
		"You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
	end
end 

def save_thank_you_letters(id, form_letter)
	Dir.mkdir("../output") unless Dir.exists? "../output"

	filename = "../output/thanks_#{id}.html"

	File.open(filename, "w") do |file|
		file.puts form_letter
	end
end

puts "EventManager Initialized!\n\n"

contents = CSV.open "../event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "../form_letter.erb"
erb_template = ERB.new template_letter

contents.each do |row|
	id = row[0]
	name = row[:first_name]

	avg_hour_signup(row[:regdate])

	#clean_phone_number isn't used for anything. Assignment calls for cleaning
	#phone numbers as they are parsed through the iterator.
	phone_number = clean_phone_number(row[:homephone].gsub(/\W+/, ""))

	#clean_zipcode and the rest of the method calls below are used to format a
	#thank you letter and to input data into our ERB file. 
	zipcode = clean_zipcode(row[:zipcode])

	legislators = legislators_by_zipcode(zipcode)

	form_letter = erb_template.result(binding)

	save_thank_you_letters(id, form_letter)
end

#This is just to output which hour, on average, people seem to register.
#Will be outputting additional information, such as the hours that the most
#people register in (not just the average).
puts "The average hour that the most people have registered during is '#{$dt_array.inject(0.0) { |total, elem| total + elem } / ($dt_array.length)}'" 

