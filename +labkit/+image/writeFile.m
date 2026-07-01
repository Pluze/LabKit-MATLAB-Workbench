function writeFile(imageData, filepath)
%WRITEFILE Write one image file, creating the parent folder when needed.
%
% App-facing contract:
%   labkit.image.writeFile(imageData, filepath)
%
% Inputs:
%   imageData - numeric image data accepted by imwrite.
%   filepath - output file path text scalar. The filename extension controls
%       the image format through MATLAB imwrite.
%
% Outputs:
%   None. imwrite errors propagate to the caller so app-owned export code can
%       record app-specific status and messages.

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
