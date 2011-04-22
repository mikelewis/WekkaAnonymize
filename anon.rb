require 'csv'

class Annon
  attr_reader :secure_attrs
  attr_reader :columns
  attr_reader :buckets
  def initialize(file_name)
    @file_name = file_name
    pre_proccess
  end

  private

  def pre_proccess
    @columns = {}
    @secure_attrs = []
    @buckets = {}
    File.open(@file_name, 'r') do |data_file|
      data_file.each do |line|
        next if line.chomp.empty?
        if line.start_with?('@')
          #attributes
          line.match(/@attribute\s+(\w+)/){|m| @columns[m[1]] = @columns.size}
          #secure attrs(assuming these are listed after attributes)
          line.match(/@secure\s+(\w+)/){|m|@secure_attrs << @columns[m[1]]}
        else
          #csv lines
          csved = line.parse_csv
          @secure_attrs.each do |secure_attr|
            ((@buckets[csved[-2].to_sym] ||= {})[secure_attr] ||= []) << csved[secure_attr]
          end
        end
      end
    end
  end

end

anonymize = Annon.new("donations-original_with_secure.arff")
p anonymize.secure_attrs
p anonymize.columns
p anonymize.buckets
