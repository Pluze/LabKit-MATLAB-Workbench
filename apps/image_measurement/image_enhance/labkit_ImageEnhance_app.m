function varargout = labkit_ImageEnhance_app(varargin)
%LABKIT_IMAGEENHANCE_APP Image enhancement and color matching app for figures.

    [varargout{1:nargout}] = image_enhance.definition().launch(varargin{:});
end
