"""Shared helpers for the Postal & Administrative Reference (PT/ES) pipeline."""

from pathlib import Path

import geopandas as gpd
import shapely
import topojson as tj

# --------------------------------------------------------------------------
# Project paths
# --------------------------------------------------------------------------
ROOT_DIR = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT_DIR / "data" / "raw"
MANUAL_DIR = ROOT_DIR / "data" / "manual"
PROCESSED_DIR = ROOT_DIR / "data" / "processed"
OUTPUTS_DIR = ROOT_DIR / "outputs"
SQL_DIR = ROOT_DIR / "sql"

# Every notebook reads from and writes to this single GeoPackage.
# Each layer name is the final export name (e.g. "PostalCodes2024_PT_ES").
LAYERS_GPKG = PROCESSED_DIR / "layers.gpkg"

# NUTS 2 codes of the archipelagos and autonomous cities outside the mainland
ARCHIPELAGO_NUTS2_IDS = ["PT20", "PT30", "ES53", "ES63", "ES64", "ES70"]

# Projected CRS used for geometric calculations (ETRS89-LAEA Europe)
PROJECTED_CRS = 3035
OUTPUT_CRS = 4326


# --------------------------------------------------------------------------
# Reading and writing intermediate layers
# --------------------------------------------------------------------------
def save_layer(gdf, layer_name):
    """Save a GeoDataFrame as a layer of data/processed/layers.gpkg (overwrites the layer)."""
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    gdf.to_file(LAYERS_GPKG, layer=layer_name, driver="GPKG")
    print(f"Saved layer '{layer_name}' ({len(gdf)} rows)")


def load_layer(layer_name):
    """Read one layer from data/processed/layers.gpkg."""
    return gpd.read_file(LAYERS_GPKG, layer=layer_name)


# --------------------------------------------------------------------------
# Geometry helpers
# --------------------------------------------------------------------------
def add_centroids(gdf):
    """Add LonCent / LatCent columns.

    Centroids are calculated in a projected CRS (metres) and then converted
    back to EPSG:4326, which avoids the geographic-CRS centroid warning.
    """
    gdf = gdf.copy()
    centroids = gdf.geometry.to_crs(PROJECTED_CRS).centroid.to_crs(OUTPUT_CRS)
    gdf["LonCent"] = centroids.x
    gdf["LatCent"] = centroids.y
    return gdf


def remove_archipelagos(gdf, archipelagos_geometry):
    """Subtract the dissolved archipelago polygon from every geometry of gdf."""
    gdf = gdf.copy()
    gdf["geometry"] = gdf.geometry.difference(archipelagos_geometry)
    return gdf


def add_spatial_id(points_gdf, poly_gdf, poly_id_col, out_col, predicate="within"):
    """Assign to each point the ID of the polygon that contains it (spatial join)."""
    if poly_gdf.crs is None:
        raise ValueError(f"The polygon GeoDataFrame ({poly_id_col}) has no CRS defined.")

    poly = poly_gdf[[poly_id_col, "geometry"]].copy()
    if poly.crs != points_gdf.crs:
        poly = poly.to_crs(points_gdf.crs)

    joined = gpd.sjoin(points_gdf[["geometry"]], poly, how="left", predicate=predicate)
    first_match = joined.groupby(level=0)[poly_id_col].first()

    points_gdf = points_gdf.copy()
    points_gdf[out_col] = points_gdf.index.map(first_match)
    return points_gdf


# --------------------------------------------------------------------------
# Geometry simplification
# --------------------------------------------------------------------------
def is_polygon_layer(gdf):
    """True when the layer has polygons (point layers are not simplified)."""
    return gdf.geom_type.isin(["Polygon", "MultiPolygon"]).all()


def count_vertices(gdf):
    """Total number of vertices (coordinates) of all geometries."""
    return int(shapely.get_num_coordinates(gdf.geometry.values).sum())


def geojson_size_mb(gdf):
    """Approximate size (MB) of the layer when written as GeoJSON."""
    return len(gdf.to_json().encode("utf-8")) / 1_000_000


def build_topology(gdf):
    """Build the topology of a layer in a projected CRS (metres).

    Borders shared by two neighbouring polygons become a single arc, so
    simplifying an arc changes both polygons in the same way.
    """
    return tj.Topology(gdf.to_crs(PROJECTED_CRS), prequantize=False)


def _keep_polygons(geom):
    """Repair an invalid geometry and keep only its polygon parts."""
    if geom.is_valid:
        return geom
    repaired = shapely.make_valid(geom)
    if repaired.geom_type in ("Polygon", "MultiPolygon"):
        return repaired
    polygons = [part for part in shapely.get_parts(repaired) if part.geom_type in ("Polygon", "MultiPolygon")]
    return shapely.union_all(polygons)


def simplify_from_topology(topology, original_gdf, tolerance_m):
    """Simplify a topology with a tolerance in metres and return it in EPSG:4326.

    Safeguards:
    * invalid geometries are repaired (make_valid);
    * a geometry that becomes empty keeps its original shape.
    """
    simplified = topology.toposimplify(tolerance_m).to_gdf()
    simplified = simplified.set_crs(PROJECTED_CRS, allow_override=True).to_crs(OUTPUT_CRS)

    # Same rows and column order as the original layer
    simplified = simplified.set_index(original_gdf.index)[original_gdf.columns]

    simplified["geometry"] = simplified.geometry.apply(_keep_polygons)
    empty = simplified.geometry.is_empty
    simplified.loc[empty, "geometry"] = original_gdf.loc[empty, "geometry"]
    return gpd.GeoDataFrame(simplified, geometry="geometry", crs=OUTPUT_CRS)


def topology_errors_km2(gdf):
    """Overlaps and gaps (km²) between neighbouring polygons of a layer.

    * overlaps = sum of the areas − area of the union
    * gaps = area of the holes inside the union (spaces between neighbours)
    """
    projected = gdf.to_crs(PROJECTED_CRS)
    union = projected.union_all()
    overlaps = projected.area.sum() - union.area

    gaps = 0.0
    for polygon in shapely.get_parts(union):
        for ring in polygon.interiors:
            gaps += shapely.Polygon(ring).area
    # max(0, ...) removes tiny negative values caused by rounding
    return round(max(0, overlaps) / 1_000_000, 3), round(max(0, gaps) / 1_000_000, 3)


def to_multipolygon(gdf):
    """Convert Polygon geometries to MultiPolygon (one geometry type per database column)."""
    gdf = gdf.copy()
    gdf["geometry"] = [
        shapely.MultiPolygon([geom]) if geom.geom_type == "Polygon" else geom
        for geom in gdf.geometry
    ]
    return gdf


# --------------------------------------------------------------------------
# Export
# --------------------------------------------------------------------------
def export_geojson_topojson(gdf, name, subfolder):
    """Export a GeoDataFrame to outputs/geojson/<subfolder> and outputs/topojson/<subfolder>."""
    geojson_path = OUTPUTS_DIR / "geojson" / subfolder / f"{name}.geojson"
    topojson_path = OUTPUTS_DIR / "topojson" / subfolder / f"{name}.json"
    geojson_path.parent.mkdir(parents=True, exist_ok=True)
    topojson_path.parent.mkdir(parents=True, exist_ok=True)

    gdf_temp = gdf.copy()
    if "name" not in gdf_temp.columns:
        gdf_temp["name"] = gdf_temp.index.astype(str)

    try:
        gdf_temp.to_file(geojson_path, driver="GeoJSON")
        print(f"Saved '{name}' as GeoJSON")
    except Exception as e:
        print(f"Error saving '{name}' as GeoJSON: {e}")

    try:
        tj.Topology(gdf_temp).to_json(topojson_path)
        print(f"Saved '{name}' as TopoJSON")
    except Exception as e:
        print(f"Error converting '{name}' to TopoJSON: {e}")
