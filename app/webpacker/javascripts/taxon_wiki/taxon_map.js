import L from 'leaflet/dist/leaflet'

var mymap = L.map('mapid').setView([40, -0.09], 2);
// https://tile.gbif.org/4326/omt/{z}/{x}/{y}@3x.png?style=osm-bright
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: 'Map data &copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors'
}).addTo(mymap);

var occurrenceData = L.tileLayer(`${gon.gbif_map_url}`, {
    attribution: `Occurrence data &copy; <a href="${gon.gbif_species_url}" target="_blank">GBIF</a></a>`,
    maxZoom: 18
});

occurrenceData.addTo(mymap);