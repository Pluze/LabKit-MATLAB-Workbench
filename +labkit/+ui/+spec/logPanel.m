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
%   minRows - optional minimum visible log rows used by automatic layout.
%   minHeight - optional minimum panel row height in pixels.
%   Log panels follow the latest appended line by default. Users can right-click
%   the log to pause or resume automatic scrolling.
%
% Output:
%   spec - scalar data-only UI spec struct.

    props = optionStruct(varargin);
    props.title = char(string(titleText));
    spec = makeSpec('logPanel', id, props, {}, struct());
end
