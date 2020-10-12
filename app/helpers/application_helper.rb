module ApplicationHelper

  def multiple_link_to(items)
    items.map do |item|
      link_to(item[:text], item[:path])
    end.join(' / ').html_safe
  end

  def boolean_to_icon(boo)
    if boo
      content_tag(:i, class: 'fas fa-check') { ; }
    else
      content_tag(:i, class: 'fas fa-minus') { ; }
    end
  end

  def links_as_ul(args)
    render 'layouts/ul', activerecord_entries: args[:activerecord_entries]
    # TODO: doesn't work... how can I use partials in helper methods?
  end

  def links_as_ul_without_partial(activerecord_entries)
    content_tag :ul do
      activerecord_entries.map do |entry, id|
        content_tag :li do
          concat(link_to(entry, taxon_path(id)))
        end
      end.join.html_safe
    end
  end

  # used for orthogroup function realm
  def array_to_ul(entries)
    content_tag :ul do
      entries.map do |entry|
        content_tag :li do
          concat(entry)
        end
      end.join.html_safe
    end
  end

  #NESTED GROUPS WITH ACCORDION

  def card_header(group)
    content_tag :div, class: "card-header", id: "heading#{group.scientific_name}" do
      button_tag class: "btn btn-link collapsed", type: "button", "data-toggle": "collapse", "data-target": "#collapse#{group.scientific_name}", "aria-expanded": "false", "aria-controls": "collapse#{group.scientific_name}" do
        concat(content_tag(:i, "", class: "fa fa-plus"))
        concat(group.scientific_name)
      end
    end
  end

  def collapse_show(sub_groups, scientific_name)
    content_tag :div, class: "collapse", "aria-labelledby": "heading#{scientific_name}", id: "collapse#{scientific_name}" do
      content_tag :div, class: "card-body" do
        content_tag :table do
          sub_groups.map do |group, sub_groups|
            content_tag :tr do
              content_tag :td do
                information_status = (TaxonomicLevel.find_by scientific_name: group.scientific_name).information_status
                link_to group.scientific_name, species_wiki_path(group.scientific_name), class: "taxonomicAccordionLink", id: information_status
              end
            end
          end.join.html_safe
        end
      end
    end
  end

  def nested_accordion(groups)
    this_id = "taxonomyAccordion"
    content_tag :div, class: "accordion", id: "#{this_id}" do
      groups.map do |group, sub_groups|
        content_tag :div, class: "card" do
          concat(card_header(group))
          concat(collapse_show(sub_groups, group.scientific_name))
        end
      end.join.html_safe
    end
  end

  def nested_groups(groups)
    content_tag(:ul) do
      groups.map do |group, sub_groups|
        if group.ancestors.length == 1
          content_tag :li, (group.scientific_name + nested_accordion(sub_groups)).html_safe
        else
          content_tag(:li, (group.scientific_name + nested_groups(sub_groups)).html_safe)
        end
      end.join.html_safe
    end
  end
end
