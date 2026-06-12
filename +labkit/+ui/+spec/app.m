function spec = app(id, titleText, varargin)
%APP Create a declarative LabKit workbench app spec.
%
% App-facing contract:
%   spec = labkit.ui.spec.app(id, title, "controlTabs", tabs, ...
%       "workspace", workspace, "position", pos, "leftWidth", width)
%
% Inputs:
%   id - globally unique app spec id and valid MATLAB field name.
%   titleText - app figure title.
%   controlTabs - cell row vector of tab specs.
%   workspace - workspace spec for right-side preview/plot/canvas content.
%   position - optional figure position, default [90 70 1200 800].
%   leftWidth - optional left control pane width, default 420.
%
% Output:
%   spec - scalar data-only UI spec struct consumed by labkit.ui.app.create.

    props = optionStruct(varargin);
    props.title = char(string(titleText));
    spec = makeSpec('app', id, props, {}, struct());
end
