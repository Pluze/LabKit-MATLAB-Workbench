function spec = logPanel(id, titleText, varargin)
%LOGPANEL Create a read-only log panel spec.
%
% App-facing contract:
%   spec = labkit.ui.spec.logPanel(id, title, "value", lines)
%
% Inputs:
%   id - globally unique log panel id.
%   titleText - log panel title.
%   value - initial log lines as text or cellstr, default {'Ready.'}.
%
% Output:
%   spec - scalar data-only UI spec struct.

    props = optionStruct(varargin);
    props.title = char(string(titleText));
    spec = makeSpec('logPanel', id, props, {}, struct());
end
