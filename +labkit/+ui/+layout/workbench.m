function layout = workbench(id, titleText, varargin)
%WORKBENCH Create a declarative LabKit workbench layout.
%
% Usage:
%   layout = labkit.ui.layout.workbench(id, titleText, "controlTabs", tabs, ...
%       "workspace", workspace)
%   layout = labkit.ui.layout.workbench(..., Name=Value)
%
% Inputs:
%   id - Text scalar used to identify the app layout. It must be a valid MATLAB
%       variable name and unique within the layout tree.
%   titleText - Text used for the app figure title.
%
% Required Name-Value Arguments:
%   controlTabs - Nonempty cell row vector of tab nodes for the left control
%       pane.
%   workspace - One workspace node for the right content pane.
%
% Optional Name-Value Arguments:
%   usage - Static workflow instructions as text, a string array, or cellstr.
%       When nonempty, a read-only Usage section is appended to the first tab.
%       Default: no usage section.
%   usageTitle - Title of the generated usage section. Default: "Usage".
%
% Outputs:
%   layout - Scalar app node consumed by labkit.ui.runtime.create or by the
%       Layout callback of labkit.ui.runtime.define.
%
% Description:
%   workbench is the root of a declarative LabKit UI tree. Every node ID in the
%   tree must be unique. Launch validation rejects missing tabs or workspace,
%   invalid child types, empty sections, and app-owned pixel geometry such as
%   position, height, padding, or pane width. The function constructs data only;
%   it does not open a figure.
%
% Example:
%   controls = labkit.ui.layout.tab("main", "Main", { ...
%       labkit.ui.layout.section("commands", "Commands", { ...
%       labkit.ui.layout.action("run", "Run", [])})});
%   content = labkit.ui.layout.workspace("workspace", "Preview", {});
%   appLayout = labkit.ui.layout.workbench("exampleApp", "Example App", ...
%       "controlTabs", {controls}, "workspace", content);
%   assert(appLayout.kind == "app")
%
% See also labkit.ui.runtime.define, labkit.ui.runtime.create,
%   labkit.ui.layout.tab, labkit.ui.layout.workspace

    props = optionStruct(varargin);
    props.title = char(string(titleText));
    props = addUsagePanelToFirstTab(id, props);
    layout = makeLayoutNode('app', id, props, {}, struct());
end

function props = addUsagePanelToFirstTab(appId, props)
    if ~isfield(props, 'usage') || isempty(props.usage) || ...
            ~isfield(props, 'controlTabs') || isempty(props.controlTabs)
        return;
    end

    tabs = props.controlTabs;
    firstTab = tabs{1};
    usageId = [char(string(appId)) 'Usage'];
    sectionId = [usageId 'Section'];
    titleText = optionValue(props, 'usageTitle', 'Usage');
    panel = usagePanel(usageId, titleText, ...
        'value', props.usage);
    firstTab.children{end+1} = labkit.ui.layout.section( ...
        sectionId, titleText, {panel});
    tabs{1} = firstTab;
    props.controlTabs = tabs;
    removeNames = intersect(fieldnames(props), ...
        {'usage', 'usageTitle'});
    if ~isempty(removeNames)
        props = rmfield(props, removeNames);
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
