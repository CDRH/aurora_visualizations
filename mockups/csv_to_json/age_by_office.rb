require 'csv'
require 'json'

ages = []

CSV.foreach("age_by_office.csv", headers: true) do |row|
  ages << {
    "office" => row["office"],
    "age" => row["age"],
    "count" => row["count"]
  }
end

File.open("../data/age_by_office.js", "w") do |f|
  f.write("var age_by_offices = #{ages.to_json};")
end
