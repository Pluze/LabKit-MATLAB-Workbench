function layout = toolPanel(id, labelText, varargin)
%TOOLPANEL Create an app-neutral host for reusable UI tools.
%
% App-facing contract:
%   layout = labkit.ui.layout.toolPanel(id, label, opts...)
%
% Inputs:
%   id - globally unique semantic id for the tool host.
%   labelText - short accessible label for the hosted tool area.
%   opts - optional name/value properties. This layout node intentionally does not
%       expose concrete layout knobs; LabKit owns the host size and spacing.
%
% Output:
%   layout - scalar data-only UI layout struct. App runners can pass the
%       registered host grid to reusable tools such as labkit.ui.interaction.scaleBar.

    props = optionStruct(varargin);
    props.label = char(string(labelText));
    layout = makeLayoutNode('toolPanel', id, props, {}, struct());
end
