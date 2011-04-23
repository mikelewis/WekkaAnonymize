require 'csv'

#core extension
class Array
  def destructive_sample_except(except_num)
    rand_val = rand(self.size)
    until self[rand_val] != except_num do
      rand_val = rand(self.size)
    end

    delete_at(rand_val)
  end

end

class Anon
  attr_reader :secure_attrs, :columns, :buckets
  def initialize(file_name)
    @file_name = file_name
    pre_process
    check_validity
  end

  def process
    File.open(@file_name, 'r') do |data_file|
      File.open("out_#{@file_name}", 'w') do |out_file|
        until (line = data_file.gets).start_with?("@data") do
          out_file.puts line unless line.start_with?("@secure") || line.match("@attribute security")
        end
        out_file.puts "@data"
        data_file.each do |line|
          csved = line.parse_csv
          #skip instances with security 2
          securty_val = csved.pop
          next if securty_val == "2"
          unless line.chomp.empty? || securty_val == "0"
            @secure_attrs.each do |secure_attr|
              bucket = csved[-1]

              rand_val = 
                if @buckets[bucket][secure_attr].size == 1
                  @buckets[bucket][secure_attr].first[1]
                else
                  @buckets[bucket][secure_attr].destructive_sample_except([data_file.lineno, csved[secure_attr]])[1]
                end

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
      until (line = data_file.gets).start_with?("@data") do 
        #attributes
        line.match(/@attribute\s+(\w+)/){|m| @columns[m[1]] = @columns.size}
        #secure attrs(assuming these are listed after attributes)
        line.match(/@secure\s+(\w+)/){|m|@secure_attrs << @columns[m[1]]}
      end
      data_file.each do |line|
        #csv lines
        csved = line.parse_csv
        @secure_attrs.each do |secure_attr|
          ((@buckets[csved[-2]] ||= {})[secure_attr] ||= []) << [data_file.lineno, csved[secure_attr]]
        end
      end
    end
  end

  def check_validity
    buckets.each do |k,v|
      if v.first[1].size == 1
        raise "Need more than one instance per class"
      end
    end
  end

end

if __FILE__ == $0
  abort "#{$0} file_name" unless ARGV.size == 1
  puts "Preproccessing"
  begin
    anonymize = Anon.new(ARGV[0])
    puts "Processing"
    anonymize.process
    puts "Done"
  rescue RuntimeError => e
    p "Error! : #{e.message}"
  end
end


