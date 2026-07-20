% App session factory; rebuilds transient table, selection, and workspace state.
function session = createSession(project, context)
%CREATESESSION Rebuild transient source-grid and selection state.
%
% Expected caller: Runtime through ttest_wizard.definition. The optional
% current source is resolved through the runtime context and read strictly into
% a transient cell grid; copied groups remain durable in project state.
% Existing unreadable sources throw so project loading cannot silently erase
% the table. Reading is the only side effect.

    arguments
        project (1, 1) struct
        context (1, 1) labkit.app.CallbackContext
    end

    source = ttest_wizard.sourceTable.emptySource();
    if ~isempty(project.inputs.sources)
        paths = context.resolveSourcePaths(project.inputs.sources);
        filepath = paths(1);
        source = ttest_wizard.sourceTable.readSourceTable( ...
            filepath, project.inputs.sourceSheet);
    end
    session = struct( ...
        "selection", struct( ...
        "sourceCells", zeros(0, 2), ...
        "selectionMessage", "Select cells in the source table.", ...
        "analysisCells", zeros(0, 2), ...
        "batchGroupTarget", "(select group)"), ...
        "cache", struct("source", source));
end
