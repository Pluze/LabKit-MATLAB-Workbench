function spec = statusPanel(id, titleText, varargin)
%STATUSPANEL Create a read-only status/details panel spec.
%
% App-facing contract:
%   spec = labkit.ui.spec.statusPanel(id, title, "value", lines)
%
% Inputs:
%   id - globally unique status panel id.
%   titleText - status panel title.
%   value - initial text or cellstr, default ''.
%   minRows - optional minimum visible text rows used by automatic layout.
%   minHeight - optional minimum panel row height in pixels.
%
% Output:
%   spec - scalar data-only UI spec struct.

    props = optionStruct(varargin);
    props.title = char(string(titleText));
    spec = makeSpec('statusPanel', id, props, {}, struct());
end
