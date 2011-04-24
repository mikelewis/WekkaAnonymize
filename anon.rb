class Anon
  attr_reader :secure_attrs, :columns, :buckets
  def initialize(file_name)
    @file_name = file_name
    pre_process
  end

  def process
    File.open("out_#{@file_name}", 'w') do |out_file|
      @headers.each do |line|
        out_file.puts line unless line.start_with?("@secure") || line.start_with?("@attribute security")
      end
      out_file.puts "@data"
      @data_lines.each do |csved|
        #skip instances with security 2
        securty_val = csved.pop
        next if securty_val == "2"
        unless csved.empty? || securty_val == "0"
          @secure_attrs.each do |secure_attr|
            bucket = csved[-1]

            rand_val = 
              if @buckets[bucket][secure_attr].size == 1
                @buckets[bucket][secure_attr].first[1]
              else
                @buckets[bucket][secure_attr].pop[1]
              end

            csved[secure_attr] = rand_val
          end
        end
        out_file.puts csved.join(',')
      end
    end
  end

  private

  def pre_process
    @columns = {}
    @secure_attrs = []
    @buckets = {}
    @data_lines = []
    @headers = []
    File.open(@file_name, 'r') do |data_file|
      until (line = data_file.gets).start_with?("@data") do 
        @headers << line
        #attributes
        line.match(/@attribute\s+(\w+)/){|m| @columns[m[1]] = @columns.size}
        #secure attrs(assuming these are listed after attributes)
        line.match(/@secure\s+(\w+)/){|m|@secure_attrs << @columns[m[1]]}
      end
      data_file.each_with_index do |line, i|
        csved = line.chomp.split(',')
        @data_lines << csved
        @secure_attrs.each do |secure_attr|
          ((@buckets[csved[-2]] ||= {})[secure_attr] ||= []) << [i, csved[secure_attr]]
        end
      end
    end

    post_pre_process
  end

  def post_pre_process
    @buckets.each do |klass, secure_attrs|
      if secure_attrs.first[1].size == 1
        raise "Need more than one instance per class"
      end
      secure_attrs.each do |attr, l|
        l.shuffle!
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


