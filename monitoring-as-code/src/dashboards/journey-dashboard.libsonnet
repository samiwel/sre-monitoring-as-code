// This file is for generating the journey dashboards which show information for each SLI in the
// journey

// Grafana imports
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;

local debug(obj) = (
  std.trace(std.toString(obj), obj)
);

local dashboardInfo (sliKey, slis) =
  {	
    //local sli = slis[elem],
    //local tr = std.trance(std.toString(slis), slis),

    local row = 0,
    local findSli(elem, slis) = slis[std.objectFields(slis)[elem]],
    panels:
      [
      // Status panel indicating SLO performance over last reporting period (30d by default)
      [findSli(elem, slis).slo_availability_panel { gridPos: { x: 0, y: elem * row, w: 4, h: 6 } }]
      +
      // Graph panel showing remaining error budget for reportinhg period (30d by default) over
      // selectable number of days
      [findSli(elem, slis).error_budget_panel { gridPos: { x: 4, y: elem * row, w: 10, h: 6 } }]
      +
      // Transparent text panel added to make spacing for slo status panel correct
      [grafana.text.new(title = null, transparent = true) + { gridPos: { x: 14, y: elem * row, w: 0.5, h: 1 } }]
      +
      // Status of SLO (pass/fail) for same time period as detail graph below
      [findSli(elem, slis).slo_status_panel { gridPos: { x: 14.5, y: elem * row, w: 9, h: 1 } }]
      +
      // Detail graph for this SLI, generated by metric specific library
      [findSli(elem, slis).graph { gridPos: { x: 14, y: elem * row, w: 10, h: 5 } }]
      for elem in std.range(0, std.length(std.objectFields(slis)) - 1 )

    ],
    dashboard: [ [grafana.row.new(title = sliKey)] + self.panels[0]]
 };

// Creates the journey view dashboards for each journey in the service
// @param config The config for the service defined in the mixin file
// @param sliList The list of SLIs for a service
// @param links The links to other dashboards
// @returns JSON defining the journey view dashboards for a service
local createJourneyDashboards(config, sliList, links) =
  {
    [std.join('-', [config.product, journeyKey, 'journey-view.json'])]:
      dashboard.new(
        title = '%(product)s-%(journey)s-journey-view' % {
          product: config.product,
          journey: journeyKey,
        },
        uid = std.join('-', [config.product, journeyKey, 'journey-view']),
        tags = [config.product, 'mac-version: %s' % config.macVersion, journeyKey, 'journey-view'],
        schemaVersion = 18,
        editable = true,
        time_from = 'now-3h',
        refresh = '5m',
      ).addLinks(
       dashboardLinks = links
      ).addTemplate(
        template.custom(
          name = 'error_budget_span',
          query = '10m,1h,1d,7d,21d,30d,90d',
          current = '7d',
          label = 'Error Budget Display',
        )
      ).addTemplates(
        config.templates
      ).addPanels(
        std.flattenArrays([
          std.flattenArrays(dashboardInfo(sliKey, sliList[journeyKey][sliKey]).dashboard)
          //debug(dashboardInfo(sliKey, sliList[journeyKey][sliKey]))
          for sliKey in std.objectFields(sliList[journeyKey])
        ])
      )
    for journeyKey in std.objectFields(sliList)
  };

// File exports
{
  createJourneyDashboards(config, sliList, links): createJourneyDashboards(config, sliList, links),
}
