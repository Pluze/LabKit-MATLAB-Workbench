classdef (Hidden, Sealed) CallbackContextFactory
    % Internal construction boundary for callback capability ports.

    methods (Static)
        function context = create(backend)
            context = labkit.app.CallbackContext(backend);
        end

    end
end
