window.customColors = {
    "white":"#ffffff",
    "off-white":"#f5f5f5",
    "gray":"#939393",
    "dark-gray":"#343a40",
    "yellowish-green":"#9ea369",
    "unreliable":"#a393bf",
    "reliable":"#7a306c",
    "annual":"#b1d1c8",
    "biennial":"#617c75",
    "perennial": "#2c5147",
    "autotroph":"#48b1f2",
    "facultative":"#176893",
    "obligate":"#38596b",
    "holoparasitic":"#022347",
    "meager":"#EEEBD3",
    "decent":"#255957",
    "good":"#437C90"
};

$(document).on('turbolinks:load', function(){
    $(".alert").delay(2000).slideUp(500, function(){
        $(".alert").alert('close');
    });
});