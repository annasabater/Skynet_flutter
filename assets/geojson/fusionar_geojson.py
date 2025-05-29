import json

# Approximate bounding box for Catalonia
CATALONIA_BBOX = {
    "min_lon": 0.0,
    "max_lon": 3.3,
    "min_lat": 40.5,
    "max_lat": 42.9
}

def is_within_catalonia(coords):
    """Checks if a single coordinate [lon, lat] is within Catalonia's bounding box."""
    # Ensure coords is a list/tuple of two numbers
    if not (isinstance(coords, (list, tuple)) and len(coords) == 2 and
            all(isinstance(c, (int, float)) for c in coords)):
        # print(f"Invalid coordinate format: {coords}") # Optional: for debugging
        return False
    lon, lat = coords
    return (CATALONIA_BBOX["min_lon"] <= lon <= CATALONIA_BBOX["max_lon"] and
            CATALONIA_BBOX["min_lat"] <= lat <= CATALONIA_BBOX["max_lat"])

def check_geometry_bounds(geometry_coords, geom_type):
    """
    Checks if any relevant part of a geometry is within Catalonia.
    For Polygons/MultiPolygons, it checks the first point of the exterior ring.
    For Points, it checks the point itself.
    For LineStrings/MultiLineStrings, it checks the first point.
    More complex checks (e.g., centroid, intersection) would require a geospatial library.
    """
    if geom_type == "Point":
        return is_within_catalonia(geometry_coords)
    elif geom_type == "LineString":
        if geometry_coords and len(geometry_coords) > 0:
            return is_within_catalonia(geometry_coords[0])
    elif geom_type == "Polygon":
        # Check the first coordinate of the outer ring
        if geometry_coords and len(geometry_coords) > 0 and \
           geometry_coords[0] and len(geometry_coords[0]) > 0:
            return is_within_catalonia(geometry_coords[0][0])
    elif geom_type == "MultiPoint":
        if geometry_coords and len(geometry_coords) > 0:
            return is_within_catalonia(geometry_coords[0]) # Check first point
    elif geom_type == "MultiLineString":
        if geometry_coords and len(geometry_coords) > 0 and \
           geometry_coords[0] and len(geometry_coords[0]) > 0:
            return is_within_catalonia(geometry_coords[0][0]) # Check first point of first linestring
    elif geom_type == "MultiPolygon":
        # Check the first coordinate of the first polygon's outer ring
        if geometry_coords and len(geometry_coords) > 0 and \
           geometry_coords[0] and len(geometry_coords[0]) > 0 and \
           geometry_coords[0][0] and len(geometry_coords[0][0]) > 0:
            return is_within_catalonia(geometry_coords[0][0][0])
    return False


def filter_geojson_for_catalonia(input_geojson_path, output_geojson_path):
    """
    Filters a GeoJSON FeatureCollection to keep only features likely within Catalonia.
    """
    try:
        with open(input_geojson_path, 'r', encoding='utf-8') as f:
            geojson_data = json.load(f)
    except FileNotFoundError:
        print(f"Error: El archivo de entrada '{input_geojson_path}' no fue encontrado.")
        return
    except json.JSONDecodeError:
        print(f"Error: El archivo '{input_geojson_path}' no es un JSON válido.")
        return

    filtered_features = []
    if geojson_data.get("type") == "FeatureCollection":
        for feature in geojson_data.get("features", []):
            geometry = feature.get("geometry")
            if geometry:
                geom_type = geometry.get("type")
                coordinates = geometry.get("coordinates")

                if coordinates is not None: # Ensure coordinates exist
                    if check_geometry_bounds(coordinates, geom_type):
                        filtered_features.append(feature)

    filtered_geojson = {
        "type": "FeatureCollection",
        "features": filtered_features
    }

    with open(output_geojson_path, 'w', encoding='utf-8') as f:
        json.dump(filtered_geojson, f, indent=2, ensure_ascii=False)

    print(f"Archivo original procesado: '{input_geojson_path}'")
    print(f"Número original de features: {len(geojson_data.get('features', []))}")
    print(f"Número de features filtradas (dentro de Cataluña): {len(filtered_features)}")
    print(f"Archivo filtrado guardado como: '{output_geojson_path}'")

# --- CONFIGURACIÓN ---
# Cambia estos nombres de archivo según sea necesario
input_file = "zguas_aero.geojson"  # El nombre de TU archivo GeoJSON de entrada
output_file = "ZGUAS_Aero_Catalunya_filtrado.geojson" # El nombre que quieras para el archivo de salida
# --- FIN DE CONFIGURACIÓN ---

if __name__ == "__main__":
    filter_geojson_for_catalonia(input_file, output_file)