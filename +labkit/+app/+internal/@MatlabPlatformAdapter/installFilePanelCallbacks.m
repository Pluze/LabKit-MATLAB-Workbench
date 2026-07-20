function installFilePanelCallbacks(obj, node, list)
% Class-folder implementation of MatlabPlatformAdapter.installFilePanelCallbacks.
    handles = list.UserData;
    list.ValueChangedFcn = @(src, ~) obj.Runtime.applyFilePanelSelection( ...
        node.Id, labkit.app.internal.NativeAdapterValues.selectedIndices(src));
    handles.Choose.ButtonPushedFcn = @(~, ~) obj.chooseFiles(node.Id);
    if ~isempty(handles.Folder)
        handles.Folder.ButtonPushedFcn = @(~, ~) ...
            obj.chooseFolderFiles(node.Id, false);
    end
    if ~isempty(handles.RecursiveFolder)
        handles.RecursiveFolder.ButtonPushedFcn = @(~, ~) ...
            obj.chooseFolderFiles(node.Id, true);
    end
    if ~isempty(handles.Remove)
        handles.Remove.ButtonPushedFcn = @(~, ~) ...
            obj.removeSelectedFiles(node.Id, list);
    end
    if ~isempty(handles.Clear)
        handles.Clear.ButtonPushedFcn = @(~, ~) ...
            obj.Runtime.applyFileSelection( ...
            node.Id, strings(1, 0), zeros(1, 0));
    end
end
