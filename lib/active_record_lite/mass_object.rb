class MassObject
  def self.my_attr_accessible(*attributes)
    # convert to array of symbols in case the user gives you strings.
    @attributes = attributes.map { |attr_name| attr_name.to_sym }

    attributes.each do |attribute|
      # add setter/getter methods
      attr_accessor attribute
    end
  end

  def self.attributes
    @attributes
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end


  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      if self.class.attributes.include?(attr_name)
        self.send("#{attr_name}=", value)
      else
        raise "mass assignment to unregistered attribute #{attr_name}"
      end
    end
  end
end
