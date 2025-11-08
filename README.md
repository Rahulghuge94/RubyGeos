# RubyGeos

**Geos lib implementation to work with InfoWorks ICM Ruby**

> **Note:** This project is in an **early development phase**. The API and functionality may change, and features may be incomplete or unstable. Contributions and feedback are welcome!

---

## Overview

RubyGeos is a Ruby extension designed to interface with the [GEOS](https://trac.osgeo.org/geos/) (Geometry Engine - Open Source) library, optimized for use within [InfoWorks ICM](https://www.innovyze.com/en-us/products/infoworks-icm). It provides geometrical and spatial operations, allowing seamless manipulation of geometric data in Ruby for flood modeling and GIS tasks.

## Features

- Ruby bindings for the GEOS library
- Geometry creation, manipulation, and analysis
- Suitable for integration with InfoWorks ICM/WSPro Ruby scripting environment

## Installation

Clone the repository:

```shell
git clone https://github.com/Rahulghuge94/RubyGeos.git
cd RubyGeos
```
Or add to your Gemfile if using Bundler:

```ruby
gem 'ffi'
```

## Usage

**Including RubyGeos in InfoWorks ICM Ruby scripting:**

InfoWorks ICM uses its own embedded Ruby instance, so you must ensure RubyGeos is in the `$LOAD_PATH`. Adjust the path as required:

```ruby
# Update the load path to point to the RubyGeos lib directory
$LOAD_PATH.unshift('C:/path/to/RubyGeos')

# Now require the main file/module
require 'rubygeos'

# Example: Create a geometry and buffer it
ctx = RubyGEOS::Context.new
puts "1. POINT GEOMETRIES"
begin
  point1 = ctx.create_point(0, 0)
  point2 = ctx.create_point(10, 10)
  puts "  Point 1: #{point1.to_wkt}"
  puts "  Point 2: #{point2.to_wkt}"
  puts "  Distance: #{point1.distance(point2)}"
rescue => e
  puts "  ERROR: #{e.message}"
end

# 2. LineString
puts "\n2. LINESTRING GEOMETRIES"
begin
  line = ctx.create_line_string([[0, 0], [10, 0], [10, 10]])
  puts "  Line: #{line.to_wkt}"
  puts "  Length: #{line.length}"
  puts "  Is valid: #{line.valid?}"
rescue => e
  puts "  ERROR: #{e.message}"
end

# 3. Polygon
puts "\n3. POLYGON GEOMETRIES"
begin
  poly1 = ctx.create_polygon([[0, 0], [10, 0], [10, 10], [0, 10], [0, 0]])
  poly2 = ctx.create_polygon([[5, 5], [15, 5], [15, 15], [5, 15], [5, 5]])
  puts "  Polygon 1: #{poly1.to_wkt}"
  puts "  Polygon 2: #{poly2.to_wkt}"
  puts "  Area 1: #{poly1.area}"
  puts "  Area 2: #{poly2.area}"
rescue => e
  puts "  ERROR: #{e.message}"
end
    
```

**Note:** Replace `C:/path/to/RubyGeos/lib` with your actual path.

## Requirements

- Ruby >= 2.5 (tested on 2.7+ and ICM Ruby)
- [GEOS library](https://trac.osgeo.org/geos/) installed on your system
- [ffi](https://github.com/ffi/ffi) Ruby gem (if library uses FFI bindings)

## Development

Contributions, bug reports, and feature requests are welcome.

## License

This project is licensed under the GNU General Public License.

## References

- [GEOS C++ Library](https://libgeos.org/)
- [InfoWorks ICM Ruby Scripting](https://boards.autodesk.com/icm/items/infoworks-icm-exchange)
- [Ruby FFI](https://github.com/ffi/ffi)

---

*Maintained by [Rahul Ghuge](https://github.com/Rahulghuge94)*
