% Expected caller: labkit_ImageMatch_app UI refresh. Input is a method label.
% Output is display text describing the selected reference-match pipeline.
function lines = matchFlowLines(method)

    key = lower(regexprep(char(string(method)), '[^a-zA-Z0-9]', ''));
    switch key
        case 'whitebalance'
            lines = {
                'White balance match'
                '1. Estimate bright low-chroma points in source and reference.'
                '2. Apply RGB diagonal gains to align source white point to reference.'
                '3. Blend result by Strength.'
                'Best for microscope background or illumination color shifts.'};
        case 'toneonly'
            lines = {
                'Tone only match'
                '1. Convert source and reference to Lab.'
                '2. Match L* percentiles for brightness and contrast.'
                '3. Keep a*/b* color channels unchanged.'
                'Best for exposure and contrast drift without changing sample color.'};
        case 'labstyle'
            lines = {
                'Lab style match'
                '1. Convert source and reference to Lab.'
                '2. Match L* percentiles using Tone strength.'
                '3. Match a*/b* mean and covariance using Color strength.'
                'Best for global color style and sample/skin color harmonization.'};
        case 'histogram'
            lines = {
                'Histogram match'
                '1. Convert source and reference to Lab.'
                '2. Match L*, a*, and b* quantiles channel-by-channel.'
                '3. Blend tone and color channels separately.'
                'Strongest match; may overfit if images contain different content.'};
        otherwise
            lines = {
                'Balanced match'
                '1. Align white point to the reference image.'
                '2. Match Lab L* brightness and contrast percentiles.'
                '3. Match Lab a*/b* color covariance.'
                'Default for figure images with illumination and color drift.'};
    end
end
