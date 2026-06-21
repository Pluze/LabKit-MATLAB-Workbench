function spec = statusPanel(id, titleText, varargin)
%STATUSPANEL Create a read-only status/details panel spec.
%
% App-facing contract:
%   spec = labkit.ui.spec.statusPanel(id, title, "value", lines)
%
% Inputs:
%   id - globally unique status panel id.
%   titleText - status panel title.
%   value - initial text or cellstr, default ''. Use app-level usage for
%       static first-page workflow instructions.
%   Concrete text-panel sizing is owned by the framework.
%
% Output:
%   spec - scalar data-only UI spec struct.

    props = optionStruct(varargin);
    props.title = char(string(titleText));
    spec = makeSpec('statusPanel', id, props, {}, struct());
end
