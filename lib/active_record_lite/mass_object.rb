class MassObject
  # takes a list of attributes.
  # adds attributes to whitelist.
  def self.my_attr_accessible(*attributes)
    @attributes ||= []

    @attributes += attributes
  end

  # takes a list of attributes.
  # makes getters and setters
  def self.my_attr_accessor(*attributes)
    attributes.each do |attribute|
      define_getter_method(attribute)
      define_setter_method(attribute)
    end
  end

  def self.define_getter_method(attribute)
    define_method(attribute) do
      instance_variable_get("@#{attribute}")
    end
  end

  def self.define_setter_method(attribute)
    define_method("#{attribute}=") do |val|
      instance_variable_set("@#{attribute}", val)
    end
  end

  # returns list of attributes that have been whitelisted.
  def self.attributes
    @attributes
  end

  # takes an array of hashes.
  # returns array of objects.
  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  my_attr_accessible :name
  my_attr_accessor :name

  # takes a hash of { attr_name => attr_val }.
  # checks the whitelist.
  # if the key (attr_name) is in the whitelist, the value (attr_val)
  # is assigned to the instance variable.
  def initialize(params = {})
    params.each do |attr_name, attr_val|
      # puts "attr_name: #{attr_name}, val: #{attr_val}"
      # p self.class.attributes
      if self.class.attributes.include?(attr_name.to_sym)
        self.send("#{attr_name}=", attr_val)
      else
        raise "mass assignment to unregistered attribute #{attr_name}"
      end
    end
  end
end

# MassObject.attributes
# MassObject.methods  - MassObject.class.methods
# m = MassObject.new(:name => "sol")
#
# p m.name
# m.name = "bill"
#
# p m.name

# Massobject.new