classdef (Sealed) Layout
    %LAYOUT Disposable immutable semantic-layout representation prototype.
    %   Static control, preview, container, workspace, and root constructors
    %   reject invalid concepts. page and initialPage are workspace-owned
    %   composition methods. flatten is compiler-facing prototype support.
    properties (SetAccess = private)
        Kind (1, 1) string
        Id (1, 1) string
        ControlKind (1, 1) string
        Children (1, :) cell
        Pages (1, :) cell
        InitialPage (1, 1) string
        Capabilities (1, :) string
    end

    methods (Access = private)
        function obj = Layout(kind, id, controlKind, children, pages, ...
                initialPage, capabilities)
            obj.Kind = kind;
            obj.Id = id;
            obj.ControlKind = controlKind;
            obj.Children = children;
            obj.Pages = pages;
            obj.InitialPage = initialPage;
            obj.Capabilities = capabilities;
        end
    end

    methods (Static)
        function obj = control(id, kind)
            arguments
                id (1, 1) string {mustBeValidId}
                kind (1, 1) string {mustBeControlKind}
            end
            capabilities = controlCapabilities(kind);
            obj = valueproto.Layout("control", id, kind, {}, {}, "", ...
                capabilities);
        end

        function obj = preview(id)
            arguments
                id (1, 1) string {mustBeValidId}
            end
            obj = valueproto.Layout("preview", id, "", {}, {}, "", ...
                ["plot", "interaction", "visible"]);
        end

        function obj = container(id, children)
            arguments
                id (1, 1) string {mustBeValidId}
                children (1, :) cell
            end
            mustBeLayouts(children);
            obj = valueproto.Layout("container", id, "", children, {}, ...
                "", strings(1, 0));
        end

        function obj = workspace(content)
            arguments
                content (1, :) cell = {}
            end
            mustBeLayouts(content);
            obj = valueproto.Layout("workspace", "workspace", "", ...
                content, {}, "", "workspacePage");
        end

        function obj = root(children)
            arguments
                children (1, :) cell
            end
            mustBeLayouts(children);
            obj = valueproto.Layout("root", "application", "", children, ...
                {}, "", strings(1, 0));
        end
    end

    methods
        function obj = page(obj, id, title, content, options)
            arguments
                obj (1, 1) valueproto.Layout
                id (1, 1) string {mustBeValidId}
                title (1, 1) string {mustBeNonempty}
                content (1, 1) valueproto.Layout
                options.AvailableWhen (1, 1) string = ""
            end
            mustBeWorkspace(obj);
            if any(cellfun(@(page) page.Id == id, obj.Pages))
                error("prototype:ui:DuplicateId", ...
                    "Workspace page ID is duplicated: %s", id);
            end
            page = struct("Id", id, "Title", title, "Content", content, ...
                "AvailableWhen", options.AvailableWhen);
            obj.Pages{end + 1} = page;
        end

        function obj = initialPage(obj, id)
            arguments
                obj (1, 1) valueproto.Layout
                id (1, 1) string {mustBeValidId}
            end
            mustBeWorkspace(obj);
            if ~any(cellfun(@(page) page.Id == id, obj.Pages))
                error("prototype:ui:UnknownReference", ...
                    "Unknown workspace page ID: %s", id);
            end
            obj.InitialPage = id;
        end

        function nodes = flatten(obj)
            chunks = cell(1, 1 + numel(obj.Children) + numel(obj.Pages));
            chunks{1} = {obj};
            cursor = 1;
            for k = 1:numel(obj.Children)
                cursor = cursor + 1;
                chunks{cursor} = obj.Children{k}.flatten();
            end
            for k = 1:numel(obj.Pages)
                cursor = cursor + 1;
                chunks{cursor} = obj.Pages{k}.Content.flatten();
            end
            nodes = [chunks{:}];
        end
    end
end

function mustBeValidId(value)
    if strlength(value) == 0 || ~isvarname(char(value))
        error("prototype:ui:InvalidValue", ...
            "ID must be a nonempty valid MATLAB name: %s", value);
    end
end

function mustBeNonempty(value)
    if strlength(value) == 0
        error("prototype:ui:InvalidValue", "Text must not be empty.");
    end
end

function mustBeControlKind(value)
    allowed = ["action", "field", "file", "table", "status"];
    if ~any(value == allowed)
        error("prototype:ui:InvalidValue", ...
            "Unsupported control kind: %s", value);
    end
end

function capabilities = controlCapabilities(kind)
    switch kind
        case "action"
            capabilities = ["enabled", "visible", "text"];
        case "field"
            capabilities = [ ...
                "value", "choices", "limits", "enabled", "visible", "text"];
        case "file"
            capabilities = [ ...
                "files", "selection", "status", "enabled", "visible"];
        case "table"
            capabilities = ["table", "enabled", "visible"];
        case "status"
            capabilities = ["text", "visible"];
    end
end

function mustBeLayouts(values)
    if ~all(cellfun(@(value) isa(value, "valueproto.Layout"), values))
        error("prototype:ui:InvalidValue", ...
            "Layout children must be valueproto.Layout values.");
    end
end

function mustBeWorkspace(value)
    if value.Kind ~= "workspace"
        error("prototype:ui:UnsupportedOperation", ...
            "page and initialPage are owned by workspace.");
    end
end
