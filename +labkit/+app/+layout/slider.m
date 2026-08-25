function node = slider(id, varargin)
%SLIDER Add a bounded numeric slider.
%
% Usage:
%   node = labkit.app.layout.slider(id, Name=Value)
%
% Description:
%   Declares one bounded scalar slider with a paired numeric spinner. Dragging
%   updates only the native value display. Runtime commits the final slider
%   value once when the pointer is released. Rapid spinner changes are
%   latest-wins coalesced and commit after a short quiet interval. A value
%   equal to the committed value is a no-op. Direct-manipulation commits do
%   not show busy feedback, so OnValueChanged must remain short and must not
%   perform unbounded or potentially long IO/calculation, export, waiting, or
%   per-adjustment logging. One bounded current preview or automatic refresh
%   may run after commit; use an explicit Run, Generate, Import, or Export
%   action when the work cannot meet an interactive response budget.
%
% Inputs:
%   id - Unique MATLAB identifier for the layout target.
%
% Options:
%   Label - Display text. Default: id.
%   Value - Finite numeric scalar. Default: lower Limits value.
%   Limits - Increasing finite numeric 1-by-2 row. Default: [0 1].
%   Step - Positive numeric scalar. Default: [].
%   ValueDisplayFormat - Optional spinner numeric format such as "%.6g".
%       Default: "".
%   Bind - Project or session field path. Default: "".
%   Enabled - Initial logical enabled state. Default: true.
%   OnValueChanged - Scalar callback
%       state = callback(state,value,context), invoked once for the committed
%       value rather than for intermediate drag or spinner values. Default: [].
%   Every slider must declare Bind or OnValueChanged.
%
% Outputs:
%   node - Immutable internal layout node accepted by layout containers.
%
% Errors:
%   Throws labkit:app:contract:* for invalid IDs, options, or callbacks.
%
% Typical Call:
%   node = labkit.app.layout.slider("frame", Limits=[1 100], Step=1, ...
%       Bind="session.frame");
%
% See also labkit.app.layout.field, labkit.app.layout.rangeField
node = labkit.app.internal.contract.LayoutNode.slider(id, varargin{:});
end
