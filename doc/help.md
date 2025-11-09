# RubyGEOS Module Documentation

## Overview

This module provides Ruby bindings for the **GEOS** C library (`geos_c.dll`) using Fiddle. It allows for the creation, manipulation, and analysis of geospatial geometries directly from Ruby.

The two primary classes you will interact with are:

  * `RubyGEOS::Context`: The main entry point. It manages the GEOS environment, memory, and serves as a factory for creating geometries.
  * `RubyGEOS::Geometry`: Represents a single GEOS geometry (e.g., a Point, Polygon, or Collection) and contains all the methods for spatial analysis and operations.

## Quick Start: Basic Usage

All operations must be wrapped in a `Context` block. The `begin...ensure...end` pattern is **essential** to prevent memory leaks.

```ruby
require_relative 'rubygeos'

# 1. Create a context
ctx = RubyGEOS::Context.new

begin
  # 2. Create geometries
  poly1_wkt = "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))"
  poly2_wkt = "POLYGON((5 5, 15 5, 15 15, 5 15, 5 5))"

  poly1 = ctx.read_wkt(poly1_wkt)
  poly2 = ctx.read_wkt(poly2_wkt)

  # 3. Perform operations
  if poly1.intersects?(poly2)
    intersection = poly1.intersection(poly2)
    
    puts "Geometries intersect!"
    puts "Intersection WKT: #{intersection.to_wkt}"
    puts "Intersection Area: #{intersection.area}"
  else
    puts "Geometries do not intersect."
  end

ensure
  # 4. Clean up the context
  # This frees all memory associated with this context.
  ctx.finish
end
```

-----

## `RubyGEOS::Context`

This class is the manager for the GEOS environment. All geometries are "owned" by the context they were created in.

### `new`

Creates and initializes a new GEOS context handle. All geometry operations must be performed using a single context.

  * **Usage:** `ctx = RubyGEOS::Context.new`

### `finish`

Destroys the context and **frees all associated memory**, including all geometries, WKT readers/writers, and other resources created within it.

  * **Note:** This is the most important method for preventing memory leaks. It **must** be called when you are done. The recommended way is with a `begin...ensure...end` block.
  * **Usage:** `ctx.finish`

### `read_wkt(wkt_string)`

Parses a **WKT (Well-Known Text)** string and returns a new `RubyGEOS::Geometry` object.

  * **Arguments:**
      * `wkt_string` (String): The WKT representation of a geometry.
  * **Returns:** `RubyGEOS::Geometry`
  * **Usage:** `point = ctx.read_wkt("POINT(10 20)")`

### `create_point(x, y, z = nil)`

Creates a new Point geometry from coordinates.

  * **Arguments:**
      * `x` (Float): The X coordinate.
      * `y` (Float): The Y coordinate.
      * `z` (Float, optional): The Z coordinate.
  * **Returns:** `RubyGEOS::Geometry`
  * **Usage:** `pt = ctx.create_point(1.2, 3.4)`

### `create_line_string(coords)`

Creates a new LineString geometry from an array of coordinate pairs.

  * **Arguments:**
      * `coords` (Array): An array of `[x, y]` pairs. e.g., `[[0, 0], [1, 1], [2, 0]]`
  * **Returns:** `RubyGEOS::Geometry`
  * **Usage:** `line = ctx.create_line_string([[0, 0], [10, 10]])`

### `create_linear_ring(coords)`

Creates a new LinearRing geometry. A LinearRing is a LineString that is both **closed** (first and last points are identical) and **simple** (does not self-intersect). This is primarily used to build Polygons.

  * **Arguments:**
      * `coords` (Array): An array of `[x, y]` pairs. The first and last pair must be identical.
  * **Returns:** `RubyGEOS::Geometry`
  * **Usage:** `ring = ctx.create_linear_ring([[0, 0], [10, 0], [10, 10], [0, 0]])`

### `create_polygon(exterior, holes = [])`

Creates a new Polygon geometry.

  * **Arguments:**
      * `exterior` (Array): An array of `[x, y]` coordinate pairs for the outer shell, (e.g., `[[0, 0], [10, 0], [0, 10], [0, 0]]`).
      * `holes` (Array, optional): An *array of arrays* of `[x, y]` coordinates. Each inner array defines one hole.
  * **Returns:** `RubyGEOS::Geometry`
  * **Usage:**
    ```ruby
    # Simple polygon
    shell = [[0, 0], [10, 0], [10, 10], [0, 10], [0, 0]]
    poly = ctx.create_polygon(shell)

    # Polygon with one hole
    hole1 = [[2, 2], [8, 2], [8, 8], [2, 8], [2, 2]]
    poly_with_hole = ctx.create_polygon(shell, [hole1])
    ```

### `create_multi_point(geometries)`

Creates a new MultiPoint collection from an array of Point `Geometry` objects.

  * **Arguments:**
      * `geometries` (Array): An array of `RubyGEOS::Geometry` objects (which should be Points).
  * **Returns:** `RubyGEOS::Geometry` (of type MultiPoint)

### `create_multi_line_string(geometries)`

Creates a new MultiLineString collection from an array of LineString `Geometry` objects.

  * **Arguments:**
      * `geometries` (Array): An array of `RubyGEOS::Geometry` objects.
  * **Returns:** `RubyGEOS::Geometry` (of type MultiLineString)

### `create_multi_polygon(geometries)`

Creates a new MultiPolygon collection from an array of Polygon `Geometry` objects.

  * **Arguments:**
      * `geometries` (Array): An array of `RubyGEOS::Geometry` objects.
  * **Returns:** `RubyGEOS::Geometry` (of type MultiPolygon)

### `create_geometry_collection(geometries)`

Creates a new GeometryCollection from an array of mixed `Geometry` objects.

  * **Arguments:**
      * `geometries` (Array): An array of any `RubyGEOS::Geometry` objects.
  * **Returns:** `RubyGEOS::Geometry` (of type GeometryCollection)

-----

## `RubyGEOS::Geometry`

Represents a single geometry. These objects are created by `Context` factory methods (e.g., `ctx.read_wkt(...)`).

### Attributes

  * `ptr`: The raw `Fiddle::Pointer` to the underlying C-level GEOS object.
  * `context`: The handle of the `RubyGEOS::Context` that owns this geometry.

### Lifecycle Management

These methods manage the C-level memory of the geometry.

### `destroy`

Manually frees the C-level geometry and removes its Ruby finalizer. After calling this, the object is un-usable.

  * **Note:** This is usually not necessary, as `ctx.finish` cleans up everything. However, it can be useful for freeing memory in long-running loops.

### `detach!`

Detaches the Ruby finalizer from the object. This is a **critical** internal-use method. It is used to transfer memory ownership to a *new* GEOS object. For example, when you pass a `LinearRing` to `create_polygon`, GEOS takes ownership of the ring. This method prevents Ruby from *also* trying to free the ring, which would cause a **double-free** crash.

### `destroyed?`

Returns `true` if `destroy` or `detach!` has been called on this object.

### `clone`

Returns a **new** `RubyGEOS::Geometry` object that is a deep copy of the C-level geometry.

### Inspection & Serialization

### `to_wkt`

Returns the **WKT (Well-Known Text)** string representation of the geometry.

  * **Returns:** `String`
  * **Usage:** `puts my_poly.to_wkt`

### `geom_type`

Returns the geometry type as a human-readable string.

  * **Returns:** `String` (e.g., "Point", "Polygon", "MultiLineString")

### `type_id`

Returns the integer constant for the geometry type.

  * **Returns:** `Integer` (e.g., `RubyGEOS::GEOS_POINT`, `RubyGEOS::GEOS_POLYGON`)

### Topological Predicates

These methods all take one `other` `RubyGEOS::Geometry` object and return `true` or `false`.

| Method | Description |
| :--- | :--- |
| `intersects?(other)` | Returns `true` if the geometries share any portion of space. |
| `disjoint?(other)` | Returns `true` if the geometries share no space. |
| `touches?(other)` | Returns `true` if the boundaries touch, but interiors do not. |
| `crosses?(other)` | Returns `true` if they share some, but not all, interior points. |
| `within?(other)` | Returns `true` if this geometry is completely inside the `other`. |
| `contains?(other)` | Returns `true` if this geometry completely contains the `other`. |
| `overlaps?(other)` | Returns `true` if geometries intersect and have the same dimension. |
| `equals?(other)` | Returns `true` if the geometries are spatially identical. |
| `covers?(other)` | Returns `true` if every point of `other` is a point of this geometry. |
| `covered_by?(other)` | Returns `true` if every point of this geometry is a point of `other`. |

### Geometric Operations

These methods perform a geometric operation and return a **new** `RubyGEOS::Geometry` object.

| Method | Description |
| :--- | :--- |
| `intersection(other)` | Returns a new geometry of the shared space. |
| `union(other)` | Returns a new geometry of all space from both. |
| `difference(other)` | Returns a new geometry of the space in this, but not in `other`. |
| `sym_difference(other)` | Returns a new geometry of the space in either, but not both. |
| `buffer(dist, segments=8)`| Returns a new polygon of all points within `dist` of this. |
| `convex_hull` | Returns the smallest convex polygon that contains this geometry. |
| `envelope` | Returns the bounding box (as a Polygon) of this geometry. |
| `boundary` | Returns the boundary of this geometry (e.g., line for a polygon). |
| `simplify(tolerance)` | Returns a new, simplified geometry (faster, non-topology preserving). |
| `simplify_preserve_topology(tolerance)` | Returns a new, simplified geometry that preserves topology. |
| `unary_union` | Computes the union of all components in a collection. |

### Measurements

### `area`

Returns the area of the geometry.

  * **Returns:** `Float`

### `length`

Returns the length of the geometry (e.g., for LineStrings).

  * **Returns:** `Float`

### `distance(other)`

Returns the shortest distance between this geometry and an `other` geometry.

  * **Returns:** `Float`

### `hausdorff_distance(other)`

Returns the Hausdorff distance, a measure of how far apart two geometries are.

  * **Returns:** `Float`

### Validity & Properties

### `valid?`

Returns `true` if the geometry is valid according to OGC rules (e.g., polygons not self-intersecting).

  * **Returns:** `true` or `false`

### `valid_reason`

Returns a string explaining *why* a geometry is invalid.

  * **Returns:** `String`

### `empty?`

Returns `true` if the geometry contains no points.

  * **Returns:** `true` or `false`

### `simple?`

Returns `true` if the geometry is "simple" (e.g., no self-intersections).

  * **Returns:** `true` or `false`

### `ring?`

Returns `true` if the geometry is a `LinearRing`.

  * **Returns:** `true` or `false`

### Collection Methods

These methods are for collection-type geometries (MultiPoint, MultiPolygon, etc.).

### `num_geometries`

Returns the number of sub-geometries in the collection.

  * **Returns:** `Integer`

### `get_geometry_n(n)`

Returns the Nth sub-geometry (0-indexed) from the collection.

  * **Note:** This returns a **clone** of the sub-geometry. The original is still owned by the collection.
  * **Returns:** `RubyGEOS::Geometry`

-----

## `RubyGEOS` Module Constants

These integer constants are used internally, primarily for `create_collection`.

  * `GEOS_POINT`
  * `GEOS_LINESTRING`
  * `GEOS_LINEARRING`
  * `GEOS_POLYGON`
  * `GEOS_MULTIPOINT`
  * `GEOS_MULTILINESTRING`
  * `GEOS_MULTIPOLYGON`
  * `GEOS_GEOMETRYCOLLECTION`
