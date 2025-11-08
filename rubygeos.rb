require 'fiddle'
require 'fiddle/import'

module RubyGEOS
  extend Fiddle::Importer
  
  # Load the GEOS C DLL
  dll_path = "#{File.dirname(__FILE__)}/geos_c.dll"
  dll_dir = File.dirname(dll_path)
  ENV['PATH'] = "#{dll_dir};#{ENV['PATH']}"
  
  unless File.exist?(dll_path)
    raise "GEOS DLL not found at: #{dll_path}"
  end
  
  dlload dll_path
  
  # Context management
  extern 'void* GEOS_init_r()'
  extern 'void GEOS_finish_r(void*)'
  
  # WKT Reader/Writer
  extern 'void* GEOSWKTReader_create_r(void*)'
  extern 'void* GEOSWKTReader_read_r(void*, void*, char*)'
  extern 'void GEOSWKTReader_destroy_r(void*, void*)'
  extern 'void* GEOSWKTWriter_create_r(void*)'
  extern 'char* GEOSWKTWriter_write_r(void*, void*, void*)'
  extern 'void GEOSWKTWriter_destroy_r(void*, void*)'
  
  # Geometry management
  extern 'void GEOSGeom_destroy_r(void*, void*)'
  extern 'void* GEOSGeom_clone_r(void*, void*)'
  extern 'char* GEOSGeomType_r(void*, void*)'
  extern 'int GEOSGeomTypeId_r(void*, void*)'
  extern 'int GEOSGetSRID_r(void*, void*)'
  extern 'void GEOSSetSRID_r(void*, void*, int)'
  
  # Coordinate sequences
  extern 'void* GEOSCoordSeq_create_r(void*, unsigned int, unsigned int)'
  extern 'void GEOSCoordSeq_destroy_r(void*, void*)'
  extern 'int GEOSCoordSeq_setX_r(void*, void*, unsigned int, double)'
  extern 'int GEOSCoordSeq_setY_r(void*, void*, unsigned int, double)'
  extern 'int GEOSCoordSeq_setZ_r(void*, void*, unsigned int, double)'
  extern 'int GEOSCoordSeq_getX_r(void*, void*, unsigned int, double*)'
  extern 'int GEOSCoordSeq_getY_r(void*, void*, unsigned int, double*)'
  extern 'int GEOSCoordSeq_getSize_r(void*, void*, unsigned int*)'
  
  # Geometry constructors
  extern 'void* GEOSGeom_createPoint_r(void*, void*)'
  extern 'void* GEOSGeom_createLineString_r(void*, void*)'
  extern 'void* GEOSGeom_createLinearRing_r(void*, void*)'
  extern 'void* GEOSGeom_createPolygon_r(void*, void*, void**, unsigned int)'
  extern 'void* GEOSGeom_createCollection_r(void*, int, void**, unsigned int)'
  
  # Geometry accessors
  extern 'void* GEOSGetExteriorRing_r(void*, void*)'
  extern 'int GEOSGetNumInteriorRings_r(void*, void*)'
  extern 'void* GEOSGetInteriorRingN_r(void*, void*, int)'
  extern 'void* GEOSGetGeometryN_r(void*, void*, int)'
  extern 'int GEOSGetNumGeometries_r(void*, void*)'
  # Note: GEOSGetCoordSeq_r removed - not available in all GEOS versions
  
  # Predicates
  extern 'char GEOSDisjoint_r(void*, void*, void*)'
  extern 'char GEOSTouches_r(void*, void*, void*)'
  extern 'char GEOSIntersects_r(void*, void*, void*)'
  extern 'char GEOSCrosses_r(void*, void*, void*)'
  extern 'char GEOSWithin_r(void*, void*, void*)'
  extern 'char GEOSContains_r(void*, void*, void*)'
  extern 'char GEOSOverlaps_r(void*, void*, void*)'
  extern 'char GEOSEquals_r(void*, void*, void*)'
  extern 'char GEOSCovers_r(void*, void*, void*)'
  extern 'char GEOSCoveredBy_r(void*, void*, void*)'
  
  # Operations
  extern 'void* GEOSEnvelope_r(void*, void*)'
  extern 'void* GEOSIntersection_r(void*, void*, void*)'
  extern 'void* GEOSConvexHull_r(void*, void*)'
  extern 'void* GEOSDifference_r(void*, void*, void*)'
  extern 'void* GEOSSymDifference_r(void*, void*, void*)'
  extern 'void* GEOSBoundary_r(void*, void*)'
  extern 'void* GEOSUnion_r(void*, void*, void*)'
  extern 'void* GEOSUnaryUnion_r(void*, void*)'
  extern 'void* GEOSBuffer_r(void*, void*, double, int)'
  extern 'void* GEOSSimplify_r(void*, void*, double)'
  extern 'void* GEOSTopologyPreserveSimplify_r(void*, void*, double)'
  
  # Measurements
  extern 'int GEOSArea_r(void*, void*, double*)'
  extern 'int GEOSLength_r(void*, void*, double*)'
  extern 'int GEOSDistance_r(void*, void*, void*, double*)'
  extern 'int GEOSHausdorffDistance_r(void*, void*, void*, double*)'
  
  # Validity
  extern 'char GEOSisValid_r(void*, void*)'
  extern 'char* GEOSisValidReason_r(void*, void*)'
  extern 'char GEOSisEmpty_r(void*, void*)'
  extern 'char GEOSisSimple_r(void*, void*)'
  extern 'char GEOSisRing_r(void*, void*)'
  
  # Free memory
  extern 'void GEOSFree_r(void*, void*)'
  
  # Geometry type constants
  GEOS_POINT = 0
  GEOS_LINESTRING = 1
  GEOS_LINEARRING = 2
  GEOS_POLYGON = 3
  GEOS_MULTIPOINT = 4
  GEOS_MULTILINESTRING = 5
  GEOS_MULTIPOLYGON = 6
  GEOS_GEOMETRYCOLLECTION = 7
  
  # Base Geometry class
  class Geometry
    attr_reader :ptr, :context
    
    def initialize(ptr, context)
      @ptr = ptr
      @context = context
      @destroyed = false
      
      # Register finalizer for automatic cleanup
      ObjectSpace.define_finalizer(self, self.class.finalizer(@ptr, @context))
    end
    
    def self.finalizer(ptr, context)
      proc { RubyGEOS.GEOSGeom_destroy_r(context, ptr) unless ptr.null? }
    end
    
    def destroy
      return if @destroyed
      RubyGEOS.GEOSGeom_destroy_r(@context, @ptr) unless @ptr.null?
      @destroyed = true
    end
    
    def destroyed?
      @destroyed
    end
    
    def clone
      raise "Geometry already destroyed" if @destroyed
      cloned_ptr = RubyGEOS.GEOSGeom_clone_r(@context, @ptr)
      Geometry.new(cloned_ptr, @context)
    end
    
    def to_wkt
      raise "Geometry already destroyed" if @destroyed
      writer = RubyGEOS.GEOSWKTWriter_create_r(@context)
      wkt_ptr = RubyGEOS.GEOSWKTWriter_write_r(@context, writer, @ptr)
      wkt = wkt_ptr.to_s
      RubyGEOS.GEOSFree_r(@context, wkt_ptr)
      RubyGEOS.GEOSWKTWriter_destroy_r(@context, writer)
      wkt
    end
    
    def geom_type
      raise "Geometry already destroyed" if @destroyed
      type_ptr = RubyGEOS.GEOSGeomType_r(@context, @ptr)
      type_ptr.to_s
    end
    
    def type_id
      raise "Geometry already destroyed" if @destroyed
      RubyGEOS.GEOSGeomTypeId_r(@context, @ptr)
    end
    
    # Predicates
    def disjoint?(other)
      check_predicate(other) { |o| RubyGEOS.GEOSDisjoint_r(@context, @ptr, o.ptr) }
    end
    
    def touches?(other)
      check_predicate(other) { |o| RubyGEOS.GEOSTouches_r(@context, @ptr, o.ptr) }
    end
    
    def intersects?(other)
      check_predicate(other) { |o| RubyGEOS.GEOSIntersects_r(@context, @ptr, o.ptr) }
    end
    
    def crosses?(other)
      check_predicate(other) { |o| RubyGEOS.GEOSCrosses_r(@context, @ptr, o.ptr) }
    end
    
    def within?(other)
      check_predicate(other) { |o| RubyGEOS.GEOSWithin_r(@context, @ptr, o.ptr) }
    end
    
    def contains?(other)
      check_predicate(other) { |o| RubyGEOS.GEOSContains_r(@context, @ptr, o.ptr) }
    end
    
    def overlaps?(other)
      check_predicate(other) { |o| RubyGEOS.GEOSOverlaps_r(@context, @ptr, o.ptr) }
    end
    
    def equals?(other)
      check_predicate(other) { |o| RubyGEOS.GEOSEquals_r(@context, @ptr, o.ptr) }
    end
    
    def covers?(other)
      check_predicate(other) { |o| RubyGEOS.GEOSCovers_r(@context, @ptr, o.ptr) }
    end
    
    def covered_by?(other)
      check_predicate(other) { |o| RubyGEOS.GEOSCoveredBy_r(@context, @ptr, o.ptr) }
    end
    
    # Operations
    def intersection(other)
      perform_operation(other) { |o| RubyGEOS.GEOSIntersection_r(@context, @ptr, o.ptr) }
    end
    
    def union(other)
      perform_operation(other) { |o| RubyGEOS.GEOSUnion_r(@context, @ptr, o.ptr) }
    end
    
    def difference(other)
      perform_operation(other) { |o| RubyGEOS.GEOSDifference_r(@context, @ptr, o.ptr) }
    end
    
    def sym_difference(other)
      perform_operation(other) { |o| RubyGEOS.GEOSSymDifference_r(@context, @ptr, o.ptr) }
    end
    
    def buffer(distance, segments = 8)
      raise "Geometry already destroyed" if @destroyed
      result_ptr = RubyGEOS.GEOSBuffer_r(@context, @ptr, distance, segments)
      Geometry.new(result_ptr, @context)
    end
    
    def convex_hull
      raise "Geometry already destroyed" if @destroyed
      result_ptr = RubyGEOS.GEOSConvexHull_r(@context, @ptr)
      Geometry.new(result_ptr, @context)
    end
    
    def envelope
      raise "Geometry already destroyed" if @destroyed
      result_ptr = RubyGEOS.GEOSEnvelope_r(@context, @ptr)
      Geometry.new(result_ptr, @context)
    end
    
    def boundary
      raise "Geometry already destroyed" if @destroyed
      result_ptr = RubyGEOS.GEOSBoundary_r(@context, @ptr)
      Geometry.new(result_ptr, @context)
    end
    
    def simplify(tolerance)
      raise "Geometry already destroyed" if @destroyed
      result_ptr = RubyGEOS.GEOSSimplify_r(@context, @ptr, tolerance)
      Geometry.new(result_ptr, @context)
    end
    
    def simplify_preserve_topology(tolerance)
      raise "Geometry already destroyed" if @destroyed
      result_ptr = RubyGEOS.GEOSTopologyPreserveSimplify_r(@context, @ptr, tolerance)
      Geometry.new(result_ptr, @context)
    end
    
    def unary_union
      raise "Geometry already destroyed" if @destroyed
      result_ptr = RubyGEOS.GEOSUnaryUnion_r(@context, @ptr)
      Geometry.new(result_ptr, @context)
    end
    
    # Measurements
    def area
      raise "Geometry already destroyed" if @destroyed
      area_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_DOUBLE)
      result = RubyGEOS.GEOSArea_r(@context, @ptr, area_ptr)
      raise "Failed to calculate area" if result == 0
      area_ptr[0, Fiddle::SIZEOF_DOUBLE].unpack('d')[0]
    rescue => e
      puts "Warning: area calculation failed - #{e.message}"
      0.0
    end
    
    def length
      raise "Geometry already destroyed" if @destroyed
      length_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_DOUBLE)
      result = RubyGEOS.GEOSLength_r(@context, @ptr, length_ptr)
      raise "Failed to calculate length" if result == 0
      length_ptr[0, Fiddle::SIZEOF_DOUBLE].unpack('d')[0]
    rescue => e
      puts "Warning: length calculation failed - #{e.message}"
      0.0
    end
    
    def distance(other)
      raise "Geometry already destroyed" if @destroyed
      raise "Other geometry already destroyed" if other.destroyed?
      dist_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_DOUBLE)
      result = RubyGEOS.GEOSDistance_r(@context, @ptr, other.ptr, dist_ptr)
      raise "Failed to calculate distance" if result == 0
      dist_ptr[0, Fiddle::SIZEOF_DOUBLE].unpack('d')[0]
    rescue => e
      puts "Warning: distance calculation failed - #{e.message}"
      0.0
    end
    
    def hausdorff_distance(other)
      raise "Geometry already destroyed" if @destroyed
      raise "Other geometry already destroyed" if other.destroyed?
      dist_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_DOUBLE)
      result = RubyGEOS.GEOSHausdorffDistance_r(@context, @ptr, other.ptr, dist_ptr)
      raise "Failed to calculate Hausdorff distance" if result == 0
      dist_ptr[0, Fiddle::SIZEOF_DOUBLE].unpack('d')[0]
    rescue => e
      puts "Warning: Hausdorff distance calculation failed - #{e.message}"
      0.0
    end
    
    # Validity checks
    def valid?
      raise "Geometry already destroyed" if @destroyed
      result = RubyGEOS.GEOSisValid_r(@context, @ptr)
      result == 1
    end
    
    def valid_reason
      raise "Geometry already destroyed" if @destroyed
      reason_ptr = RubyGEOS.GEOSisValidReason_r(@context, @ptr)
      reason = reason_ptr.to_s
      RubyGEOS.GEOSFree_r(@context, reason_ptr)
      reason
    end
    
    def empty?
      raise "Geometry already destroyed" if @destroyed
      result = RubyGEOS.GEOSisEmpty_r(@context, @ptr)
      result == 1
    end
    
    def simple?
      raise "Geometry already destroyed" if @destroyed
      result = RubyGEOS.GEOSisSimple_r(@context, @ptr)
      result == 1
    end
    
    def ring?
      raise "Geometry already destroyed" if @destroyed
      result = RubyGEOS.GEOSisRing_r(@context, @ptr)
      result == 1
    end
    
    # Geometry collection methods
    def num_geometries
      raise "Geometry already destroyed" if @destroyed
      RubyGEOS.GEOSGetNumGeometries_r(@context, @ptr)
    end
    
    def get_geometry_n(n)
      raise "Geometry already destroyed" if @destroyed
      geom_ptr = RubyGEOS.GEOSGetGeometryN_r(@context, @ptr, n)
      return nil if geom_ptr.null?
      # Clone because the returned geometry is owned by the parent
      cloned_ptr = RubyGEOS.GEOSGeom_clone_r(@context, geom_ptr)
      Geometry.new(cloned_ptr, @context)
    end
    
    private
    
    def check_predicate(other)
      raise "Geometry already destroyed" if @destroyed
      raise "Other geometry already destroyed" if other.destroyed?
      result = yield(other)
      result == 1
    end
    
    def perform_operation(other)
      raise "Geometry already destroyed" if @destroyed
      raise "Other geometry already destroyed" if other.destroyed?
      result_ptr = yield(other)
      Geometry.new(result_ptr, @context)
    end
  end
  
  # Context manager
  class Context
    attr_reader :handle
    
    def initialize
      @handle = RubyGEOS.GEOS_init_r
      raise "Failed to initialize GEOS context" if @handle.null?
    end
    
    def finish
      RubyGEOS.GEOS_finish_r(@handle) if @handle && !@handle.null?
      @handle = nil
    end
    
    # Factory methods
    def read_wkt(wkt_string)
      reader = RubyGEOS.GEOSWKTReader_create_r(@handle)
      geom_ptr = RubyGEOS.GEOSWKTReader_read_r(@handle, reader, wkt_string)
      RubyGEOS.GEOSWKTReader_destroy_r(@handle, reader)
      raise "Failed to parse WKT" if geom_ptr.null?
      Geometry.new(geom_ptr, @handle)
    end
    
    def create_point(x, y, z = nil)
      dims = z ? 3 : 2
      coord_seq = RubyGEOS.GEOSCoordSeq_create_r(@handle, 1, dims)
      RubyGEOS.GEOSCoordSeq_setX_r(@handle, coord_seq, 0, x)
      RubyGEOS.GEOSCoordSeq_setY_r(@handle, coord_seq, 0, y)
      RubyGEOS.GEOSCoordSeq_setZ_r(@handle, coord_seq, 0, z) if z
      geom_ptr = RubyGEOS.GEOSGeom_createPoint_r(@handle, coord_seq)
      Geometry.new(geom_ptr, @handle)
    end
    
    def create_line_string(coords)
      coord_seq = RubyGEOS.GEOSCoordSeq_create_r(@handle, coords.length, 2)
      coords.each_with_index do |(x, y), i|
        RubyGEOS.GEOSCoordSeq_setX_r(@handle, coord_seq, i, x)
        RubyGEOS.GEOSCoordSeq_setY_r(@handle, coord_seq, i, y)
      end
      geom_ptr = RubyGEOS.GEOSGeom_createLineString_r(@handle, coord_seq)
      Geometry.new(geom_ptr, @handle)
    end
    
    def create_linear_ring(coords)
      coord_seq = RubyGEOS.GEOSCoordSeq_create_r(@handle, coords.length, 2)
      coords.each_with_index do |(x, y), i|
        RubyGEOS.GEOSCoordSeq_setX_r(@handle, coord_seq, i, x)
        RubyGEOS.GEOSCoordSeq_setY_r(@handle, coord_seq, i, y)
      end
      geom_ptr = RubyGEOS.GEOSGeom_createLinearRing_r(@handle, coord_seq)
      Geometry.new(geom_ptr, @handle)
    end
    
    def create_polygon(exterior, holes = [])
      ext_ring = create_linear_ring(exterior)
      
      if holes.empty?
        geom_ptr = RubyGEOS.GEOSGeom_createPolygon_r(@handle, ext_ring.ptr, nil, 0)
      else
        hole_geoms = holes.map { |h| create_linear_ring(h) }
        hole_ptrs = hole_geoms.map { |h| h.ptr }
        
        # Create array of pointers
        holes_array = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP * holes.length)
        hole_ptrs.each_with_index do |ptr, i|
          holes_array[i * Fiddle::SIZEOF_VOIDP, Fiddle::SIZEOF_VOIDP] = [ptr.to_i].pack("Q")
        end
        
        geom_ptr = RubyGEOS.GEOSGeom_createPolygon_r(@handle, ext_ring.ptr, holes_array, holes.length)
      end
      
      raise "Failed to create polygon" if geom_ptr.null?
      Geometry.new(geom_ptr, @handle)
    rescue => e
      puts "Error creating polygon: #{e.message}"
      raise
    end
    
    def create_collection(type, geometries)
      return create_empty_collection(type) if geometries.empty?
      
      geom_ptrs = geometries.map { |g| g.ptr }
      
      # Create array of pointers
      geoms_array = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP * geometries.length)
      geom_ptrs.each_with_index do |ptr, i|
        geoms_array[i * Fiddle::SIZEOF_VOIDP, Fiddle::SIZEOF_VOIDP] = [ptr.to_i].pack("Q")
      end
      
      geom_ptr = RubyGEOS.GEOSGeom_createCollection_r(@handle, type, geoms_array, geometries.length)
      raise "Failed to create collection" if geom_ptr.null?
      Geometry.new(geom_ptr, @handle)
    rescue => e
      puts "Error creating collection: #{e.message}"
      raise
    end
    
    def create_empty_collection(type)
      geom_ptr = RubyGEOS.GEOSGeom_createCollection_r(@handle, type, nil, 0)
      raise "Failed to create empty collection" if geom_ptr.null?
      Geometry.new(geom_ptr, @handle)
    end
    
    def create_multi_point(geometries)
      create_collection(RubyGEOS::GEOS_MULTIPOINT, geometries)
    end
    
    def create_multi_line_string(geometries)
      create_collection(RubyGEOS::GEOS_MULTILINESTRING, geometries)
    end
    
    def create_multi_polygon(geometries)
      create_collection(RubyGEOS::GEOS_MULTIPOLYGON, geometries)
    end
    
    def create_geometry_collection(geometries)
      create_collection(RubyGEOS::GEOS_GEOMETRYCOLLECTION, geometries)
    end
  end
end

# Example usage demonstrating all features
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
