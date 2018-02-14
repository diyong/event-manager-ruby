require "csv"
require "google/apis/civicinfo_v2"
require "erb"
require "date"

$hour_array = []
$day_array = []

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

def signup_per_hour(date)
	$hour_array << (DateTime.strptime(date, "%m/%d/%y %k:%M")).strftime("%H").to_i
end

def most_signups_hour
	hours = $hour_array.inject(Hash.new(0)) { |hsh, val| hsh[val] += 1; hsh }.to_a.max_by(2) { |key, elem| elem }

	puts "The top 2 hours which saw the largest number of registrations are:"

	hours.each do |key, elem|
		puts "#{ elem } people registered within the #{ 24 - key.to_i } o'clock hour."
	end 
end

def signup_per_day(date)
	$day_array << Date::DAYNAMES[(DateTime.strptime(date, "%m/%d/%y %k:%M")).wday]
end

def most_signups_day
	days = $day_array.inject(Hash.new(0)) { |hsh, val| hsh[val] += 1; hsh }.to_a.max_by(2) { |key, elem| elem }

	puts "The top 2 days which saw the largest number of registrations are:"

	days.each do |key, elem|
		puts "#{ elem } people registered on a #{key}."
	end
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

	signup_per_day(row[:regdate])

	signup_per_hour(row[:regdate])

	#clean_phone_number isn't used for anything. Assignment calls for cleaning
	#phone numbers as they are parsed through the iterator.
	#phone_number = clean_phone_number(row[:homephone].gsub(/\W+/, ""))

	#clean_zipcode and the rest of the method calls below are used to format a
	#thank you letter and to input data into our ERB file. 
	#zipcode = clean_zipcode(row[:zipcode])

	#legislators = legislators_by_zipcode(zipcode)

	#form_letter = erb_template.result(binding)

	#save_thank_you_letters(id, form_letter)
end

#Additional assignment given by project. Client wishes to know which hours and 
#which days had the most registrations for advertisement purposes.
most_signups_day
puts
most_signups_hour

