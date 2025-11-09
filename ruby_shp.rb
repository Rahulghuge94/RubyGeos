# Shapefile Reader and Writer for Ruby 2.4+
# Supports reading and writing .shp, .shx, and .dbf files
# Author: Rahul Ghuge
# Date: 2025-08-10
# Script uses the ESRI Shapefile specification

module Shapefile
  # Shape types according to ESRI Shapefile specification
  SHAPE_TYPES = {
    0 => :null,
    1 => :point,
    3 => :polyline,
    5 => :polygon,
    8 => :multipoint,
    11 => :point_z,
    13 => :polyline_z,
    15 => :polygon_z,
    18 => :multipoint_z,
    21 => :point_m,
    23 => :polyline_m,
    25 => :polygon_m,
    28 => :multipoint_m,
    31 => :multipatch
  }.freeze

  SHAPE_TYPE_CODES = SHAPE_TYPES.invert.freeze

  class BoundingBox
    attr_accessor :xmin, :ymin, :xmax, :ymax, :zmin, :zmax, :mmin, :mmax

    def initialize(xmin = 0, ymin = 0, xmax = 0, ymax = 0, zmin = 0, zmax = 0, mmin = 0, mmax = 0)
      @xmin, @ymin, @xmax, @ymax = xmin, ymin, xmax, ymax
      @zmin, @zmax, @mmin, @mmax = zmin, zmax, mmin, mmax
    end

    def update(x, y, z = nil, m = nil)
      @xmin = x if x < @xmin || @xmin == 0
      @ymin = y if y < @ymin || @ymin == 0
      @xmax = x if x > @xmax
      @ymax = y if y > @ymax
      @zmin = z if z && (z < @zmin || @zmin == 0)
      @zmax = z if z && z > @zmax
      @mmin = m if m && (m < @mmin || @mmin == 0)
      @mmax = m if m && m > @mmax
    end
  end

  class Shape
    attr_accessor :type, :points, :parts, :bbox, :z_array, :m_array

    def initialize(type)
      @type = type
      @points = []
      @parts = []
      @bbox = BoundingBox.new
      @z_array = []
      @m_array = []
    end
  end

  class Record
    attr_accessor :shape, :attributes

    def initialize(shape = nil, attributes = {})
      @shape = shape
      @attributes = attributes
    end
  end

  class Reader
    attr_reader :shape_type, :bbox, :records

    def initialize(filename)
      @basename = filename.sub(/\.(shp|shx|dbf)$/i, '')
      @records = []
      read_shapefile
      read_dbf
    end

    private

    def read_shapefile
      File.open("#{@basename}.shp", 'rb') do |f|
        # Read file header (100 bytes)
        file_code = f.read(4).unpack1('N')
        raise 'Invalid shapefile' unless file_code == 9994

        f.seek(24) # Skip unused bytes
        file_length = f.read(4).unpack1('N') * 2 # Convert from 16-bit words to bytes
        version = f.read(4).unpack1('V')
        @shape_type = SHAPE_TYPES[f.read(4).unpack1('V')]

        # Read bounding box
        @bbox = BoundingBox.new(
          f.read(8).unpack1('E'),  # Xmin
          f.read(8).unpack1('E'),  # Ymin
          f.read(8).unpack1('E'),  # Xmax
          f.read(8).unpack1('E'),  # Ymax
          f.read(8).unpack1('E'),  # Zmin
          f.read(8).unpack1('E'),  # Zmax
          f.read(8).unpack1('E'),  # Mmin
          f.read(8).unpack1('E')   # Mmax
        )

        # Read records
        while f.pos < file_length
          record_number = f.read(4).unpack1('N')
          content_length = f.read(4).unpack1('N') * 2

          shape = read_shape(f)
          @records << Record.new(shape)
        end
      end
    end

    def read_shape(f)
      shape_type = f.read(4).unpack1('V')
      shape = Shape.new(SHAPE_TYPES[shape_type])

      return shape if shape_type == 0 # Null shape

      case shape.type
      when :point
        read_point(f, shape)
      when :polyline, :polygon
        read_polyline_or_polygon(f, shape)
      when :multipoint
        read_multipoint(f, shape)
      end

      shape
    end

    def read_point(f, shape)
      x = f.read(8).unpack1('E')
      y = f.read(8).unpack1('E')
      shape.points << [x, y]
    end

    def read_polyline_or_polygon(f, shape)
      # Bounding box
      xmin = f.read(8).unpack1('E')
      ymin = f.read(8).unpack1('E')
      xmax = f.read(8).unpack1('E')
      ymax = f.read(8).unpack1('E')
      shape.bbox = BoundingBox.new(xmin, ymin, xmax, ymax)

      num_parts = f.read(4).unpack1('V')
      num_points = f.read(4).unpack1('V')

      # Read parts
      num_parts.times do
        shape.parts << f.read(4).unpack1('V')
      end

      # Read points
      num_points.times do
        x = f.read(8).unpack1('E')
        y = f.read(8).unpack1('E')
        shape.points << [x, y]
      end
    end

    def read_multipoint(f, shape)
      # Bounding box
      xmin = f.read(8).unpack1('E')
      ymin = f.read(8).unpack1('E')
      xmax = f.read(8).unpack1('E')
      ymax = f.read(8).unpack1('E')
      shape.bbox = BoundingBox.new(xmin, ymin, xmax, ymax)

      num_points = f.read(4).unpack1('V')

      # Read points
      num_points.times do
        x = f.read(8).unpack1('E')
        y = f.read(8).unpack1('E')
        shape.points << [x, y]
      end
    end

    def read_dbf
      dbf_path = "#{@basename}.dbf"
      return unless File.exist?(dbf_path)

      File.open(dbf_path, 'rb') do |f|
        # Read header
        version = f.read(1).unpack1('C')
        year = f.read(1).unpack1('C') + 1900
        month = f.read(1).unpack1('C')
        day = f.read(1).unpack1('C')
        num_records = f.read(4).unpack1('V')
        header_length = f.read(2).unpack1('v')
        record_length = f.read(2).unpack1('v')

        f.seek(32) # Skip to field descriptors

        # Read field descriptors
        fields = []
        while f.pos < header_length - 1
          name = f.read(11).unpack1('Z11')
          type = f.read(1)
          f.read(4) # Skip field data address
          length = f.read(1).unpack1('C')
          decimal = f.read(1).unpack1('C')
          f.read(14) # Skip reserved bytes

          fields << { name: name, type: type, length: length, decimal: decimal }
        end

        f.read(1) # Read terminator

        # Read records
        @records.each_with_index do |record, i|
          break if i >= num_records

          deletion_flag = f.read(1)
          next if deletion_flag == '*'

          attributes = {}
          fields.each do |field|
            value = f.read(field[:length])
            attributes[field[:name]] = parse_field_value(value, field[:type])
          end

          record.attributes = attributes
        end
      end
    end

    def parse_field_value(value, type)
      value = value.strip
      return nil if value.empty?

      case type
      when 'N', 'F'
        value.include?('.') ? value.to_f : value.to_i
      when 'L'
        ['T', 't', 'Y', 'y'].include?(value)
      when 'D'
        return nil if value == '00000000'
        Date.strptime(value, '%Y%m%d') rescue nil
      else
        value
      end
    end
  end

  class Writer
    def initialize(filename, shape_type)
      @basename = filename.sub(/\.(shp|shx|dbf)$/i, '')
      @shape_type = shape_type
      @records = []
      @bbox = BoundingBox.new
      @fields = []
    end

    def add_field(name, type, length, decimal = 0)
      @fields << { name: name[0..10], type: type, length: length, decimal: decimal }
    end

    def add_record(shape, attributes = {})
      @records << Record.new(shape, attributes)
      
      # Update bounding box
      shape.points.each do |point|
        @bbox.update(point[0], point[1])
      end
    end

    def write
      write_shp
      write_shx
      write_dbf
    end

    private

    def write_shp
      File.open("#{@basename}.shp", 'wb') do |f|
        # Calculate file length
        content_length = @records.reduce(0) do |sum, record|
          sum + 4 + record_content_length(record.shape) # 4 bytes for record header
        end
        file_length = (100 + content_length) / 2 # In 16-bit words

        # Write file header
        f.write([9994].pack('N'))           # File code
        f.write([0].pack('N') * 5)          # Unused
        f.write([file_length].pack('N'))    # File length
        f.write([1000].pack('V'))           # Version
        f.write([SHAPE_TYPE_CODES[@shape_type]].pack('V')) # Shape type
        f.write([@bbox.xmin].pack('E'))
        f.write([@bbox.ymin].pack('E'))
        f.write([@bbox.xmax].pack('E'))
        f.write([@bbox.ymax].pack('E'))
        f.write([0.0].pack('E') * 4)        # Z and M ranges (unused)

        # Write records
        @records.each_with_index do |record, i|
          record_length = record_content_length(record.shape) / 2
          f.write([i + 1].pack('N'))          # Record number (1-based)
          f.write([record_length].pack('N'))  # Content length
          write_shape(f, record.shape)
        end
      end
    end

    def write_shx
      File.open("#{@basename}.shx", 'wb') do |f|
        # Write file header (same as .shp)
        file_length = (100 + @records.length * 8) / 2
        f.write([9994].pack('N'))
        f.write([0].pack('N') * 5)
        f.write([file_length].pack('N'))
        f.write([1000].pack('V'))
        f.write([SHAPE_TYPE_CODES[@shape_type]].pack('V'))
        f.write([@bbox.xmin].pack('E'))
        f.write([@bbox.ymin].pack('E'))
        f.write([@bbox.xmax].pack('E'))
        f.write([@bbox.ymax].pack('E'))
        f.write([0.0].pack('E') * 4)

        # Write index records
        offset = 50 # Start after header (in 16-bit words)
        @records.each do |record|
          content_length = record_content_length(record.shape) / 2
          f.write([offset].pack('N'))
          f.write([content_length].pack('N'))
          offset += content_length + 4 # +4 for record header
        end
      end
    end

    def write_shape(f, shape)
      shape_code = SHAPE_TYPE_CODES[shape.type]
      f.write([shape_code].pack('V'))

      return if shape_code == 0

      case shape.type
      when :point
        f.write([shape.points[0][0]].pack('E'))
        f.write([shape.points[0][1]].pack('E'))
      when :polyline, :polygon
        write_polyline_or_polygon(f, shape)
      when :multipoint
        write_multipoint(f, shape)
      end
    end

    def write_polyline_or_polygon(f, shape)
      # Calculate bounding box if not set
      if shape.bbox.xmin == 0 && shape.bbox.xmax == 0
        shape.points.each { |p| shape.bbox.update(p[0], p[1]) }
      end

      f.write([shape.bbox.xmin].pack('E'))
      f.write([shape.bbox.ymin].pack('E'))
      f.write([shape.bbox.xmax].pack('E'))
      f.write([shape.bbox.ymax].pack('E'))
      f.write([shape.parts.length].pack('V'))
      f.write([shape.points.length].pack('V'))

      shape.parts.each { |part| f.write([part].pack('V')) }
      shape.points.each do |point|
        f.write([point[0]].pack('E'))
        f.write([point[1]].pack('E'))
      end
    end

    def write_multipoint(f, shape)
      if shape.bbox.xmin == 0 && shape.bbox.xmax == 0
        shape.points.each { |p| shape.bbox.update(p[0], p[1]) }
      end

      f.write([shape.bbox.xmin].pack('E'))
      f.write([shape.bbox.ymin].pack('E'))
      f.write([shape.bbox.xmax].pack('E'))
      f.write([shape.bbox.ymax].pack('E'))
      f.write([shape.points.length].pack('V'))

      shape.points.each do |point|
        f.write([point[0]].pack('E'))
        f.write([point[1]].pack('E'))
      end
    end

    def record_content_length(shape)
      case shape.type
      when :point
        20 # 4 (shape type) + 16 (x, y)
      when :polyline, :polygon
        44 + shape.parts.length * 4 + shape.points.length * 16
      when :multipoint
        40 + shape.points.length * 16
      else
        4 # Null shape
      end
    end

    def write_dbf
      return if @fields.empty?

      File.open("#{@basename}.dbf", 'wb') do |f|
        # Calculate lengths
        header_length = 32 + @fields.length * 32 + 1
        record_length = 1 + @fields.reduce(0) { |sum, field| sum + field[:length] }

        # Write header
        f.write([3].pack('C'))                      # Version
        f.write([Time.now.year - 1900].pack('C'))   # Year
        f.write([Time.now.month].pack('C'))         # Month
        f.write([Time.now.day].pack('C'))           # Day
        f.write([@records.length].pack('V'))        # Number of records
        f.write([header_length].pack('v'))          # Header length
        f.write([record_length].pack('v'))          # Record length
        f.write([0].pack('C') * 20)                 # Reserved

        # Write field descriptors
        @fields.each do |field|
          f.write([field[:name]].pack('a11'))
          f.write([field[:type]].pack('a1'))
          f.write([0].pack('V'))                    # Field data address
          f.write([field[:length]].pack('C'))
          f.write([field[:decimal]].pack('C'))
          f.write([0].pack('C') * 14)               # Reserved
        end

        f.write([0x0D].pack('C'))                   # Header terminator

        # Write records
        @records.each do |record|
          f.write([0x20].pack('C'))                 # Deletion flag (not deleted)

          @fields.each do |field|
            value = format_field_value(record.attributes[field[:name]], field)
            f.write([value].pack("a#{field[:length]}"))
          end
        end

        f.write([0x1A].pack('C'))                   # EOF marker
      end
    end

    def format_field_value(value, field)
      return ' ' * field[:length] if value.nil?

      case field[:type]
      when 'N', 'F'
        if field[:decimal] > 0
          format("%#{field[:length]}.#{field[:decimal]}f", value.to_f)
        else
          format("%#{field[:length]}d", value.to_i)
        end
      when 'L'
        value ? 'T' : 'F'
      when 'D'
        value.respond_to?(:strftime) ? value.strftime('%Y%m%d') : '        '
      else
        value.to_s[0...field[:length]].ljust(field[:length])
      end
    end
  end
end

# Example usage:
if __FILE__ == $0
  # Writing a shapefile
  writer = Shapefile::Writer.new('./test.shp', :polygon)
  writer.add_field('NAME', 'C', 50)
  writer.add_field('AREA', 'N', 10, 2)

  # Create a simple polygon (square)
  shape = Shapefile::Shape.new(:polygon)
  shape.parts = [0]
  shape.points = [
    [0.0, 0.0],
    [10.0, 0.0],
    [10.0, 10.0],
    [0.0, 10.0],
    [0.0, 0.0]
  ]

  writer.add_record(shape, { 'NAME' => 'Square', 'AREA' => 100.0 })
  writer.write

  puts "Wrote test.shp, test.shx, test.dbf"

  # Reading the shapefile
  reader = Shapefile::Reader.new('./test.shp')
  puts "\nShape type: #{reader.shape_type}"
  puts "Bounding box: #{reader.bbox.xmin}, #{reader.bbox.ymin} - #{reader.bbox.xmax}, #{reader.bbox.ymax}"
  puts "Number of records: #{reader.records.length}"

  reader.records.each_with_index do |record, i|
    puts "\nRecord #{i + 1}:"
    puts "  Shape: #{record.shape.type}"
    puts "  Points: #{record.shape.points.length}"
    puts "  Attributes: #{record.attributes.inspect}"
  end
end