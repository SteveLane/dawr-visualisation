#!/bin/bash
# Get the shapefiles from ABS
curl -Lk 'http://www.abs.gov.au/ausstats/subscriber.nsf/log?openagent&1270055001_ste_2016_aust_shape.zip&1270.0.55.001&Data%20Cubes&65819049BE2EB089CA257FED0013E865&0&July%202016&12.07.2016&Latest' -o ../data/aust.zip
# Unzip
unzip ../data/aust.zip -d ../data/
# Convert to json
shp2json ../data/STE_2016_AUST.shp -o ../data/aust.json
# Which has these features: "features":[{"type":"Feature","properties":{"STE_CODE16":"1","STE_NAME16":"New South Wales","AREASQKM16":800810.7823}
# Projection
geoproject 'd3.geoConicEqualArea().parallels([-18, -36]).rotate([-134, 0]).fitSize([960, 960], d)' < ../data/aust.json > ../data/aust-albers.json
geo2svg -w 960 -h 960 < ../data/aust-albers.json > ../data/aust-albers.svg
# Split into newline delimited json
ndjson-split 'd.features' < ../data/aust-albers.json > ../data/aust-albers.ndjson
# Add the state ID as a top-level id
ndjson-map 'd.id = d.properties.STE_CODE16, d' < ../data/aust-albers.ndjson > ../data/aust-albers-id.ndjson
# Add a random number to each state id, and promote the area properties (whilst removing others)
ndjson-map 'd.properties = {rID: Math.random() * 50 | 0, state_id: d.properties.STE_CODE16, area: d.properties.AREASQKM16}, d' < ../data/aust-albers-id.ndjson > ../data/aust-albers-rand.ndjson
# Convert back to geojson
ndjson-reduce 'p.features.push(d), p' '{type: "FeatureCollection", features: []}' < ../data/aust-albers-rand.ndjson > ../data/aust-albers-rand.json
# Add viridis fill based on area (but let's make it smaller next)
ndjson-map -r d3 \
	   '(d.properties.fill = d3.scaleSequential(d3.interpolateViridis).domain([0, 1000000])(d.properties.area), d)' \
	   < ../data/aust-albers-rand.ndjson \
	   > ../data/aust-albers-colour.ndjson
# Make an svg of it
geo2svg -n --stroke none -p 1 -w 960 -h 960 \
	< ../data/aust-albers-colour.ndjson \
	> ../data/aust-albers-colour.svg
# OK, that seems good. Let's now make it smaller
geo2topo -n states=../data/aust-albers-rand.ndjson > ../data/aust-states-topo.json
toposimplify -p 1 -f < ../data/aust-states-topo.json > ../data/aust-simple-topo.json
topoquantize 1e5 < ../data/aust-simple-topo.json > ../data/aust-quantized-topo.json
# Now let's do the same colouring
