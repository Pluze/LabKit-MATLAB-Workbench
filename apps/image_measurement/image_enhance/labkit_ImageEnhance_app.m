function varargout = labkit_ImageEnhance_app(varargin)
%LABKIT_IMAGEENHANCE_APP Image enhancement and color matching app for figures.

    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @image_enhance.definition, @image_enhance.requirements, ...
        @image_enhance.version, varargin{:});
end
