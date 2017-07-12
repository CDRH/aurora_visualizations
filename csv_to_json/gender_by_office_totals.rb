require 'csv'
require 'json'

offices = {}

CSV.foreach("gender_by_office_totals.csv", headers: true) do |row|
  if row["office"] == "NULL"
    # skip if this is the "total results" row
    next if row["gender"] == "NULL"
    office_name = "All Offices"
  else
    office_name = row["office"]
  end
  if !offices.has_key?(office_name)
    offices[office_name] = {}
  end
  office = offices[office_name]
  # presumably gender + office combo should be unique, but checking in case not
  next if row["gender"] == "NULL"
  if office.has_key?(row["gender"])
    puts "Too many genders for #{office_name}: #{row["gender"]}, #{row["count"]}"
  else
    office[row["gender"]] = row["count"]
  end
end

File.open("../gender_by_office.js", "w") do |f|
  f.write("var gender_by_offices = #{offices.to_json};")
end
