function spec = app(id, titleText, varargin)
%APP Create a declarative LabKit workbench app spec.
%
% App-facing contract:
%   spec = labkit.ui.spec.app(id, title, "controlTabs", tabs, ...
%       "workspace", workspace)
%
% Inputs:
%   id - globally unique app spec id and valid MATLAB field name.
%   titleText - app figure title.
%   controlTabs - cell row vector of tab specs.
%   workspace - workspace spec for right-side preview/plot/canvas content.
%   usage - optional static workflow help lines. When supplied, the framework
%       adds a usagePanel at the bottom of the first control tab.
%   usageTitle - optional usage panel title, default 'Usage'.
%   Concrete layout is owned by the LabKit workbench framework, not app specs.
%
% Output:
%   spec - scalar data-only UI spec struct consumed by labkit.ui.app.create.

    props = optionStruct(varargin);
    props.title = char(string(titleText));
    props = addUsagePanelToFirstTab(id, props);
    spec = makeSpec('app', id, props, {}, struct());
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
    panel = labkit.ui.spec.usagePanel(usageId, titleText, ...
        'value', props.usage);
    firstTab.children{end+1} = labkit.ui.spec.section( ...
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
