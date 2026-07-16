function ui = create(layout, varargin)
%CREATE Build a LabKit workbench from a declarative layout.
%
% Usage:
%   ui = labkit.ui.runtime.create(layout)
%   ui = labkit.ui.runtime.create(layout, "debug", debugContext)
%
% Inputs:
%   layout - Scalar layout tree returned by labkit.ui.layout.workbench. Control
%       IDs must be unique throughout the tree.
%
% Name-Value Arguments:
%   debug - labkit.ui.debug context used to instrument the new figure and show
%       trace messages in the first log panel. The default is no debug context.
%
% Outputs:
%   ui - Struct containing the figure, shell panels, controls, tabs, workspace,
%       source layout, and debug context. Controls and sections are indexed by
%       their layout IDs.
%
% Description:
%   create builds the complete workbench immediately and returns its handle
%   registry. Use this lower-level function when code already has a finished
%   layout tree. Most apps should use labkit.ui.runtime.launch, which also owns
%   project state, actions, presentation, startup, and persistence.
%
% See also labkit.ui.runtime.launch, labkit.ui.layout.workbench

    opts = parseOptions(varargin);
    debug = optionValue(opts, 'debug', []);
    ui = buildRuntimeWorkbench(layout, debug, ...
        startupProgressReporter(struct()));
    startupLifecycle(ui.figure, 'finish', "Ready.");
end

function opts = parseOptions(args)
    if mod(numel(args), 2) ~= 0
        error('labkit:ui:runtime:InvalidOptions', ...
            'labkit.ui.runtime.create options must be name/value pairs.');
    end
    opts = struct();
    for k = 1:2:numel(args)
        opts.(char(string(args{k}))) = args{k + 1};
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
