#!/bin/bash
# Get the shapefiles from ABS
curl -Lk 'http://www.abs.gov.au/ausstats/subscriber.nsf/log?openagent&1270055001_ste_2016_aust_shape.zip&1270.0.55.001&Data%20Cubes&65819049BE2EB089CA257FED0013E865&0&July%202016&12.07.2016&Latest' -o ../data/aust.zip
# Unzip
unzip ../data/aust.zip -d ../data/

# Convert shapefile, filter out 'other states and territories',
# Add some extras to the properties, convert back to a feature collection,
# Project to a conci equal area projection.
shp2json -n ../data/STE_2016_AUST.shp \
    | ndjson-filter 'd.properties.STE_CODE16 !== "9"' \
    | ndjson-map 'd.properties = {rID: Math.random() * 50 | 0, state_id: d.properties.STE_CODE16, area: d.properties.AREASQKM16}, d' \
    | ndjson-reduce 'p.features.push(d), p' '{type: "FeatureCollection", features: []}' \
    | geoproject 'd3.geoConicEqualArea().parallels([-18, -36]).rotate([-132, 0]).center([0, -27]).fitSize([960, 600], d)' \
		 > ../data/aust-albers.json

# Now take the projected file and make it smaller
geo2topo states=../data/aust-albers.json \
    | toposimplify -p 1 -f \
    | topoquantize 1e5 \
		   > ../data/aust-topo.json
