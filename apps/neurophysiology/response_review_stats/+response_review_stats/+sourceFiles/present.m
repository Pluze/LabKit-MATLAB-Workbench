function view = present(~)
% The runtime owns opaque portable path display for bound file lists.
view = labkit.app.view.Snapshot().filePaths("inputFile", strings(0, 1));
end
