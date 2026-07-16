function writeFile(imageData, filepath)
%WRITEFILE Write one image file, creating the parent folder when needed.
%
% Usage:
%   labkit.image.writeFile(imageData, filepath)
%
% Description:
%   Writes imageData with MATLAB imwrite. The extension in filepath selects
%   the output format. If the parent folder does not exist, the function
%   creates it, including intermediate folders supported by mkdir. Existing
%   files are replaced according to imwrite behavior.
%
%   The function does not rescale, clamp, or otherwise normalize imageData.
%   Errors from folder creation and imwrite propagate to the caller.
%
% Inputs:
%   imageData - Image matrix accepted by MATLAB imwrite.
%   filepath - Nonempty character vector or scalar string. The filename
%              extension controls the output format.
%
% Outputs:
%   None.
%
% Errors:
%   labkit:image:InvalidOutputPath - filepath is empty or nonscalar.
%   Other folder and image-format errors are raised by mkdir or imwrite.
%
% Typical Call:
%   labkit.image.writeFile(processedImage, fullfile(outputFolder, "result.png"));

    filepath = string(filepath);
    if ~isscalar(filepath) || strlength(strtrim(filepath)) == 0
        error('labkit:image:InvalidOutputPath', ...
            'Image output path must be a nonempty text scalar.');
    end
    [folder, ~, ~] = fileparts(char(filepath));
    if ~isempty(folder) && exist(folder, 'dir') ~= 7
        mkdir(folder);
    end
    imwrite(imageData, char(filepath));
end
