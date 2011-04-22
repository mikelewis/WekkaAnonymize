require 'csv'

class Annon
  attr_reader :secure_attrs
  attr_reader :columns
  attr_reader :buckets
  def initialize(file_name)
    @file_name = file_name
    pre_process
  end

  def process
    File.open(@file_name, 'r') do |data_file|
      File.open("out_#{@file_name}", 'w') do |out_file|
        data_file.each do |line|
          csved = line.parse_csv
          unless line.start_with?('@') || line.chomp.empty?
            @secure_attrs.each do |secure_attr|
              until(rand_val = @buckets[csved[-2].to_sym][secure_attr].sample) != csved[secure_attr] do end
              csved[secure_attr] = rand_val
            end
          end
          out_file.puts csved.to_csv
        end
      end
    end
  end

  private

  def pre_process
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

if __FILE__ == $0
  abort "#{$0} file_name" unless ARGV.size == 1
  anonymize = Annon.new(ARGV[0])
  anonymize.process
end


