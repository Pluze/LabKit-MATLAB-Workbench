function node = fileList(id, varargin)
%FILELIST Add file selection and live source-list controls.
%
% Usage:
%   node = labkit.app.layout.fileList(id, Name=Value)
%
% Description:
%   Declares framework-owned file choosing, removal, selection, and live
%   source binding.
%
% Inputs:
%   id - Unique MATLAB identifier for the layout target.
%
% Options:
%   Label - Reader-facing collection label. Default: id.
%   Mode - "files" or "folder". Default: "files".
%   Filters - File-dialog filter text row. Default: strings(1,0).
%   SelectionMode - "single" or "multiple" for both the native file chooser
%       and list-row selection. Multi-file collections use "multiple"; a
%       single semantic input normally combines "single" with MaxFiles=1.
%       Its compact path surface wraps the complete filename and retains the
%       absolute path in hover text.
%       Default: "multiple".
%   MaxFiles - Positive scalar or Inf. Default: Inf.
%   ShowStatus - Logical status visibility. Default: true.
%   ChooseLabel - File button text. Default: "Choose".
%   FolderLabel - Folder button text. Default: "Choose Folder".
%   RecursiveFolderLabel - Recursive button text. Default: "Choose Folder Recursively".
%   RemoveLabel - Remove button text. Default: "Remove".
%   ClearLabel - Clear button text. Default: "Clear".
%   ChooseTooltip - File button hover text. Default: ChooseLabel.
%   EmptyText - Empty-list text. Default: "No files selected".
%   AllowDuplicatePaths - Preserve separate source-list records that
%       resolve to the same path. Use this when each list row is a distinct
%       workflow task. Default: false.
%   PathFilter - Optional callback accepted = callback(paths). paths is a row
%       string array containing newly proposed files. accepted must be a
%       logical row with one value per path. Rejected paths are omitted before
%       source-list records are created, and the runtime reports aggregate
%       retained/filtered counts without exposing filenames. Default: empty.
%   PathFilterDescription - Reader-facing description of files accepted by
%       PathFilter, used in the aggregate filtering notice. Default:
%       "supported".
%   Bind - App-owned source-record field path.
%   SelectionBind - ListSelection field path. Default: "".
%   OnSelectionChanged - Optional callback
%       applicationState = callback(applicationState,selection,callbackContext)
%       for business effects such as lazily decoding the selected source.
%       selection is labkit.app.event.ListSelection. Ordinary selection state
%       needs only SelectionBind. Default: empty.
%   SourceRole - Runtime source role. Default: id.
%   SourceIdPrefix - Runtime source ID prefix. Default: id.
%
% Outputs:
%   node - Immutable internal layout node accepted by layout containers.
%
% Errors:
%   Throws labkit:app:contract:* for invalid options, paths, callbacks, or
%   a missing Bind owner.
%   In a native App, an unhandled file-panel validation or parsing exception
%   is rolled back and shown in an alert.
%
% Typical Call:
%   node = labkit.app.layout.fileList("files", ...
%       Bind="inputs.sources", ...
%       ChooseTooltip="Choose calibrated source images for this analysis.");
%
% See also labkit.app.event.ListSelection,
%   labkit.app.CallbackContext, labkit.app.view.Snapshot
node = labkit.app.internal.contract.LayoutNode.fileList(id, varargin{:});
end
