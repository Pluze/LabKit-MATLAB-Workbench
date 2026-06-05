function varargout = batchImageCropWorkflow(command, varargin)
%BATCHIMAGECROPWORKFLOW Dispatch app-owned batch crop helpers.
% Expected caller: batch-crop app tests and migration-time workflow checks.
% Inputs are a workflow command plus command-specific arguments. Outputs match
% the selected app-private helper. Export commands have file side effects.

    switch string(command)
        case "cropImage"
            varargout{1} = batchCropImage(varargin{1}, varargin{2});
        case "buildBatchCropManifest"
            varargout{1} = buildBatchCropManifest(varargin{1});
        case "selectedBatchCropImagePaths"
            varargout{1} = selectedBatchCropImagePaths(varargin{1}, varargin{2});
        case "writeBatchCropOutputs"
            varargout{1} = writeBatchCropOutputs(varargin{1}, varargin{2});
        case "batchCropImageDialogFilter"
            varargout{1} = batchCropImageDialogFilter();
        otherwise
            error('labkit:BatchImageCrop:UnknownWorkflowCommand', ...
                'Unknown batch image crop workflow helper command: %s.', command);
    end
end
