function layout = logPanel(id, titleText, varargin)
%LOGPANEL Create a read-only log panel layout node.
%
% App-facing contract:
%   layout = labkit.ui.layout.logPanel(id, title, "value", lines)
%
% Inputs:
%   id - globally unique log panel id.
%   titleText - log panel title.
%   value - initial log lines as text or cellstr, default {'Ready.'}.
%   Use app-level usage, not logPanel, for static workflow help.
%   Log panels follow the latest appended line by default. Users can use the
%   visible follow button or context menu to pause or resume automatic
%   scrolling.
%   Concrete log-panel sizing is owned by the framework.
%
% Output:
%   layout - scalar data-only UI layout struct.

    props = optionStruct(varargin);
    props.title = char(string(titleText));
    layout = makeLayoutNode('logPanel', id, props, {}, struct());
end
