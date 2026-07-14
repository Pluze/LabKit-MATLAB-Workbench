% Private UI runtime helper. Expected callers: v2 commit/save/load paths. Input
% is an app figure. Side effect adds or removes the framework-owned dirty title
% marker without altering version text or app-owned title content.
function updateV2DocumentTitle(fig)
    if isempty(fig) || ~isvalid(fig) || ~isappdata(fig, appRuntimeKey())
        return;
    end
    runtime = getappdata(fig, appRuntimeKey());
    if ~isfield(runtime, 'document')
        return;
    end
    name = erase(string(fig.Name), " *");
    if runtime.document.dirty
        name = name + " *";
    end
    fig.Name = char(name);
end
