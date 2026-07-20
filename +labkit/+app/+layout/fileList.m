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
%   ChooseTooltip - File button hover text. Default: ChooseLabel.
%   FolderTooltip - Folder button hover text. Default: FolderLabel.
%   RecursiveFolderTooltip - Recursive-folder button hover text. Default:
%       RecursiveFolderLabel.
%   RemoveTooltip - Remove button hover text. Default: RemoveLabel.
%   ClearTooltip - Clear button hover text. Default: ClearLabel.
%   EmptyText - Empty-list text. Default: "No files selected".
%   AllowDuplicatePaths - Preserve separate portable source records that
%       resolve to the same path. Use this when each list row is a distinct
%       workflow task. Default: false.
%   Bind - Project source-record field path. Default: "".
%   SelectionBind - ListSelection field path. Default: "".
%   OnSelectionChanged - Optional callback
%       applicationState = callback(applicationState,selection,callbackContext)
%       for business effects such as lazily decoding the selected source.
%       selection is labkit.app.event.ListSelection. Ordinary selection state
%       needs only SelectionBind. Default: empty.
%   SourceRole - Portable source role. Default: id.
%   SourceIdPrefix - Portable source ID prefix. Default: id.
%   Required - Logical relinking requirement. Default: true.
%
% Outputs:
%   node - Immutable internal layout node accepted by layout containers.
%
% Errors:
%   Throws labkit:app:contract:* for invalid options, paths, or callbacks.
%
% Typical Call:
%   node = labkit.app.layout.fileList("files", ...
%       Bind="project.inputs.sources", ...
%       ChooseTooltip="Choose calibrated source images for this analysis.");
%
% See also labkit.app.event.ListSelection,
%   labkit.app.CallbackContext, labkit.app.view.Snapshot
node = labkit.app.internal.LayoutNode.fileList(id, varargin{:});
end
