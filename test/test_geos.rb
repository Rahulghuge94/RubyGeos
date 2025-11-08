$LOAD_PATH.unshift File.dirname(__FILE__)

require 'rubygeos'

if __FILE__ == $0
  puts "=== RubyGEOS - Full Featured Test Suite ===\n\n"
  
  ctx = RubyGEOS::Context.new
  
  begin
    # 1. Point geometries
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
    
    # 4. Polygon with holes
    puts "\n4. POLYGON WITH HOLES"
    begin
      poly_with_hole = ctx.create_polygon(
        [[0, 0], [20, 0], [20, 20], [0, 20], [0, 0]],
        [[[5, 5], [15, 5], [15, 15], [5, 15], [5, 5]]]
      )
      puts "  Polygon with hole: #{poly_with_hole.to_wkt}"
      puts "  Area: #{poly_with_hole.area}"
    rescue => e
      puts "  ERROR: #{e.message}"
    end
    
    # 5. MultiPoint
    puts "\n5. MULTIPOINT"
    begin
      multi_point = ctx.create_multi_point([
        ctx.create_point(0, 0),
        ctx.create_point(5, 5),
        ctx.create_point(10, 10)
      ])
      puts "  MultiPoint: #{multi_point.to_wkt}"
      puts "  Number of geometries: #{multi_point.num_geometries}"
    rescue => e
      puts "  ERROR: #{e.message}"
    end
    
    # 6. MultiLineString
    puts "\n6. MULTILINESTRING"
    begin
      multi_line = ctx.create_multi_line_string([
        ctx.create_line_string([[0, 0], [5, 5]]),
        ctx.create_line_string([[10, 10], [15, 15]])
      ])
      puts "  MultiLineString: #{multi_line.to_wkt}"
      puts "  Total length: #{multi_line.length}"
    rescue => e
      puts "  ERROR: #{e.message}"
    end
    
    # 7. MultiPolygon
    puts "\n7. MULTIPOLYGON"
    begin
      multi_poly = ctx.create_multi_polygon([
        ctx.create_polygon([[0, 0], [5, 0], [5, 5], [0, 5], [0, 0]]),
        ctx.create_polygon([[10, 10], [15, 10], [15, 15], [10, 15], [10, 10]])
      ])
      puts "  MultiPolygon: #{multi_poly.to_wkt}"
      puts "  Total area: #{multi_poly.area}"
    rescue => e
      puts "  ERROR: #{e.message}"
    end
    
    # 8. GeometryCollection
    puts "\n8. GEOMETRYCOLLECTION"
    begin
      geom_coll = ctx.create_geometry_collection([
        ctx.create_point(0, 0),
        ctx.create_line_string([[5, 5], [10, 10]]),
        ctx.create_polygon([[15, 15], [20, 15], [20, 20], [15, 20], [15, 15]])
      ])
      puts "  GeometryCollection: #{geom_coll.to_wkt}"
      puts "  Number of geometries: #{geom_coll.num_geometries}"
    rescue => e
      puts "  ERROR: #{e.message}"
    end
    
    # 9. Predicates
    puts "\n9. PREDICATES"
    begin
      if defined?(poly1) && defined?(poly2) && poly1 && poly2
        puts "  poly1 intersects poly2: #{poly1.intersects?(poly2)}"
        puts "  poly1 disjoint poly2: #{poly1.disjoint?(poly2)}"
        puts "  poly1 touches poly2: #{poly1.touches?(poly2)}"
        puts "  poly1 overlaps poly2: #{poly1.overlaps?(poly2)}"
        puts "  poly1 equals poly2: #{poly1.equals?(poly2)}"
      end
      if defined?(poly1) && defined?(point1) && poly1 && point1
        puts "  poly1 contains point1: #{poly1.contains?(point1)}"
        puts "  point1 within poly1: #{point1.within?(poly1)}"
        puts "  poly1 covers point1: #{poly1.covers?(point1)}"
      end
    rescue => e
      puts "  ERROR: #{e.message}"
    end
    
    # 10. Operations
    puts "\n10. OPERATIONS"
    begin
      if defined?(poly1) && defined?(poly2) && poly1 && poly2
        intersection = poly1.intersection(poly2)
        puts "  Intersection: #{intersection.to_wkt}"
        puts "  Intersection area: #{intersection.area}"
        
        union = poly1.union(poly2)
        puts "  Union: #{union.to_wkt}"
        puts "  Union area: #{union.area}"
        
        difference = poly1.difference(poly2)
        puts "  Difference: #{difference.to_wkt}"
        
        sym_diff = poly1.sym_difference(poly2)
        puts "  Symmetric difference area: #{sym_diff.area}"
      end
      
      if defined?(point1) && point1
        buffered = point1.buffer(5.0)
        puts "  Buffered point area: #{buffered.area}"
      end
      
      if defined?(multi_point) && multi_point
        hull = multi_point.convex_hull
        puts "  Convex hull: #{hull.to_wkt}"
      end
      
      if defined?(poly1) && poly1
        envelope = poly1.envelope
        puts "  Envelope: #{envelope.to_wkt}"
        
        simplified = poly1.simplify(1.0)
        puts "  Simplified: #{simplified.to_wkt}"
      end
    rescue => e
      puts "  ERROR: #{e.message}"
    end
    
    # 11. WKT parsing
    puts "\n11. WKT PARSING"
    begin
      from_wkt = ctx.read_wkt("POLYGON((0 0, 100 0, 100 100, 0 100, 0 0))")
      puts "  Parsed from WKT: #{from_wkt.to_wkt}"
      puts "  Area: #{from_wkt.area}"
    rescue => e
      puts "  ERROR: #{e.message}"
    end
    
    # 12. Geometry info
    puts "\n12. GEOMETRY INFO"
    begin
      if defined?(poly1) && poly1
        puts "  Polygon type: #{poly1.geom_type}"
        puts "  Type ID: #{poly1.type_id}"
        puts "  Is valid: #{poly1.valid?}"
        puts "  Is empty: #{poly1.empty?}"
        puts "  Is simple: #{poly1.simple?}"
      end
    rescue => e
      puts "  ERROR: #{e.message}"
    end
    
    puts "\n=== All tests completed! ==="
    
  rescue => e
    puts "\nFATAL ERROR: #{e.message}"
    puts e.backtrace.first(10)
  ensure
    ctx.finish
  end
  
  puts "\nPress Enter to exit..."
  gets
end
