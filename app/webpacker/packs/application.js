/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

/**
 * old ones still to import
 //= require components
 */

import "core-js/stable"
import "regenerator-runtime/runtime"

require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()

import "bootstrap/dist/js/bootstrap"
import "bootstrap-select/dist/js/bootstrap-select.min"

import "datatables.net-bs4"

import "../javascripts/sitwide/global"
import "../javascripts/sitwide/navbar_custom_behavior"

import "stylesheets/application"

function loadTaxonomyBrowserIndex() {
    import('../javascripts/browser_index')
}

function loadTaxonomyBrowser() {
    import('../javascripts/taxonomy_browser')
}

function loadTaxonShow() {
    import('../javascripts/taxon_wiki/taxon_show')
    import('../javascripts/taxon_wiki/taxon_map')
}

function loadTaxonEdit() {
    import('../javascripts/taxon_wiki/taxon_edit')
}

function loadTaxonNew() {
    import('../javascripts/taxon_wiki/taxon_new')
}

function loadTraitReconstruction() {
    import('../javascripts/trait_reconstruction_tree')
}

function loadOrthogroupIndex() {
    import('../javascripts/orthogroups')
}

function loadOrthogroupShow() {
    import('../javascripts/orthogroup')
}

function loadPublicationIndex() {
    import('../javascripts/publications')
}

function loadSubmissionIndex() {
    import('../javascripts/submissions')
}

function loadSubmissionShow() {
    import('../javascripts/submission_show')
}

function loadGenomeBrowserIndex() {
    import('../javascripts/genome_browsers')
}

function loadServerJobIndex() {
    import('../javascripts/server_jobs')
}

function loadPpgshow() {
    import('../javascripts/server_jobs/ppg_matches')
}

function loadPpgNew() {
    import('../javascripts/server_jobs/new_ppg')
}

function loadPpgReferenceMatches() {
    import('../javascripts/server_jobs/ppg_reference_matches')
}

function loadPpgQueriesBackground() {
    import('../javascripts/server_jobs/ppg_queries')
}

function loadBlastNew() {
    import('../javascripts/server_jobs/new_blast')
}

function loadWarppDocumentation() {
    import('../javascripts/warpp_manual')
}

document.addEventListener("turbolinks:load", () => {
    $('[data-toggle="tooltip"]').tooltip()
    $('[data-toggle="popover"]').popover()
    $('.selectpicker').selectpicker()

    if (document.getElementById('browser-index-main')) {
        loadTaxonomyBrowserIndex()
    }

    if(document.getElementById('taxonomy-browser-page')) {
        loadTaxonomyBrowser()
    }

    if(document.getElementById('taxon-show')) {
        loadTaxonShow()
    }

    if(document.getElementById('taxon-edit')) {
        loadTaxonEdit()
    }

    if(document.getElementById('taxon-new')) {
        loadTaxonNew()
    }

    if(document.getElementById('trait-reconstruction-index')) {
        loadTraitReconstruction()
    }

    if(document.getElementById('orthogroup-index')) {
        loadOrthogroupIndex()
    }

    if(document.getElementById('orthogroup-show')) {
        loadOrthogroupShow()
    }

    if(document.getElementById('publication-index')) {
        loadPublicationIndex()
    }

    if(document.getElementById('submission-index')) {
        loadSubmissionIndex()
    }

    if(document.getElementById('submission-show')) {
        loadSubmissionShow()
    }

    if(document.getElementById('genome-browser-index')) {
        loadGenomeBrowserIndex()
    }

    if(document.getElementById('server-job-index')) {
        loadServerJobIndex()
    }

    if(document.getElementById('ppg-show')) {
        loadPpgshow()
    }

    if(document.getElementById('ppg-new')) {
        loadPpgNew()
    }

    if(document.getElementById('ppg-reference-matches')) {
        loadPpgReferenceMatches()
    }

    if(document.getElementById('ppg-queries-background')) {
        loadPpgQueriesBackground()
    }

    if(document.getElementById('blast-new')) {
        loadBlastNew()
    }

    if(document.getElementById('warpp-documentation')) {
        loadWarppDocumentation()
    }
})







