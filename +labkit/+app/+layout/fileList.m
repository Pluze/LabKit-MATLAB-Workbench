function node = fileList(id, varargin)
%FILELIST Add file selection and portable-source controls.
%
% Usage:
%   node = labkit.app.layout.fileList(id, Name=Value)
%
% Description:
%   Declares framework-owned file choosing, removal, selection, and portable
%   source binding.
%
% Inputs:
%   id - Unique MATLAB identifier for the layout target.
%
% Options:
%   Label - Reader-facing collection label. Default: id.
%   Mode - "files" or "folder". Default: "files".
%   Filters - File-dialog filter text row. Default: strings(1,0).
%   SelectionMode - "single" or "multiple". Default: "multiple".
%   MaxFiles - Positive scalar or Inf. Default: Inf.
%   FolderWarningThreshold - Positive scalar or Inf. Default: 500.
%   ShowStatus - Logical status visibility. Default: true.
%   StartPath - Initial folder text. Default: "".
%   ChooseLabel - File button text. Default: "Choose".
%   FolderLabel - Folder button text. Default: "Choose Folder".
%   RecursiveFolderLabel - Recursive button text. Default: "Choose Folder Recursively".
%   RemoveLabel - Remove button text. Default: "Remove".
%   ClearLabel - Clear button text. Default: "Clear".
%   EmptyText - Empty-list text. Default: "No files selected".
%   Chosen - StateHandler with Event="listSelection". Default: [].
%   Removed - StateHandler with Event="listSelection". Default: [].
%   Cleared - StateHandler with Event="action". Default: [].
%   SelectionChanged - StateHandler with Event="listSelection". Default: [].
%   Bind - Project source-record field path. Default: "".
%   SelectionBind - ListSelection field path. Default: "".
%   SourceRole - Portable source role. Default: id.
%   SourceIdPrefix - Portable source ID prefix. Default: id.
%   Required - Logical relinking requirement. Default: true.
%
% Outputs:
%   node - Immutable internal layout node accepted by layout containers.
%
% Errors:
%   Throws labkit:app:contract:* for invalid options, paths, or handlers.
%
% Typical Call:
%   node = labkit.app.layout.fileList("files", ...
%       Bind="project.inputs.sources");
%
% See also labkit.app.event.ListSelection,
%   labkit.app.CallbackContext
node = labkit.app.internal.LayoutNode.fileList(id, varargin{:});
end
