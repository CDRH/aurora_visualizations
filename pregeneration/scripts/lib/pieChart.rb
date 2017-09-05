class PieChart
  attr_accessor :counter
  attr_reader :type

  @@mappings = {
    "destination_class" => {
      "C" => "Within County",
      "P" => "Proximate County",
      "BN" => "North or South Border",
      "N" => "North",
      "I" => "Internal South",
      "I/DS" => "Internal or Deep South",
      "U" => "Unknown"
    },
    "gender" => {
      "female" => "Female",
      "male" => "Male",
      "unknown" => "Unknown"
    },
    "group" => {
      "I" => "Individual",
      "G" => "Group",
      "F" => "Family",
      "U" => "Unknown"
    },
    "occupation" => [
      "Domestic",
      "Agricultural",
      "Other",
      "Laborer",
      "Unknown"
    ]
  }

  def self.code_to_label(type, code)
    mapping = @@mappings[type]
    if mapping.class == Hash
      return mapping[code] || "Unknown"
    elsif mapping.class == Array
      return mapping.include?(code) ? code : "Unknown"
    else
      raise "Not sure how to process mapping of class #{mapping.class}"
    end
  end

  def initialize(type)
    @type = type
    @counter = { "All" => zeroed_hash(@@mappings[type]) }
  end

  def chart_formatter
    chart_data = {}
    @counter.each do |office, office_info|
      chart_data[office] = []
      office_info.each do |property, number|
        chart_data[office] << { "property" => property, "contracts" => number }
      end
    end
    return chart_data
  end

  def tally_field(office, value)
    if !@counter.has_key?(office)
      @counter[office] = zeroed_hash(@@mappings[@type])
    end
    @counter[office][value] += 1
    @counter["All"][value] += 1
  end

  def zeroed_hash(mapping)
    if mapping.class == Hash
      mapping.map{ |k, v| [v, 0] }.to_h
    elsif mapping.class == Array
      mapping.map { |v| [v, 0] }.to_h
    else
      raise "Not sure how to process mapping of class #{mapping.class}"
    end
  end

end
