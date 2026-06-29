function spec = toolPanel(id, labelText, varargin)
%TOOLPANEL Create an app-neutral host for reusable UI tools.
%
% App-facing contract:
%   spec = labkit.ui.spec.toolPanel(id, label, opts...)
%
% Inputs:
%   id - globally unique semantic id for the tool host.
%   labelText - short accessible label for the hosted tool area.
%   opts - optional name/value properties. This spec intentionally does not
%       expose concrete layout knobs; LabKit owns the host size and spacing.
%
% Output:
%   spec - scalar data-only UI spec struct. App runners can pass the
%       registered host grid to reusable tools such as labkit.ui.tool.scaleBar.

    props = optionStruct(varargin);
    props.label = char(string(labelText));
    spec = makeSpec('toolPanel', id, props, {}, struct());
end
