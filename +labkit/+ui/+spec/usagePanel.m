function spec = usagePanel(id, titleText, varargin)
%USAGEPANEL Create a read-only workflow usage panel spec.
%
% App-facing contract:
%   spec = labkit.ui.spec.usagePanel(id, title, "value", lines)
%
% Inputs:
%   id - globally unique usage panel id.
%   titleText - usage/help panel title.
%   value - usage lines as text or cellstr, default ''.
%   Prefer app-level usage on labkit.ui.spec.app so the framework places
%       first-page workflow instructions consistently.
%   Concrete usage-panel sizing is owned by the framework.
%
% Output:
%   spec - scalar data-only UI spec struct.

    props = optionStruct(varargin);
    props.title = char(string(titleText));
    spec = makeSpec('usagePanel', id, props, {}, struct());
end
