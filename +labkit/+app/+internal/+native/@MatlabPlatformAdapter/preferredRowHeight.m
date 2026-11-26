function height = preferredRowHeight(obj, node)
% Class-folder implementation of MatlabPlatformAdapter.preferredRowHeight.
    policy = labkit.app.internal.native.NativeAdapterValues.layoutPolicy();
    key = char(node.Id);
    if isfield(obj.ContentHeights, key)
        height = obj.ContentHeights.(key);
        return
    end
    switch node.Kind
        case {"tab", "workspace", "workspacePage", "plotArea"}
            height = "1x";
        case "fileList"
            if node.Configuration.SelectionMode == "single" && ...
                    node.Configuration.MaxFiles == 1
                height = policy.CompactFileHeight;
            else
                height = policy.EmptyFileListHeight;
            end
        case "dataTable"
            height = policy.TableHeight;
        case "statusPanel"
            if node.Configuration.Presentation == "note"
                height = 18 * node.Configuration.Lines + 4;
            elseif node.Configuration.Presentation == "label"
                height = 25 + 19 * node.Configuration.Lines;
            else
                height = policy.ReadonlyMinimumHeight + 22;
            end
        case "button"
            height = policy.ButtonHeight;
        case "slider"
            height = policy.SliderHeight;
            if node.Configuration.ShowValue
                height = height + policy.FieldHeight + 4;
            elseif node.Configuration.LabelPosition == "top"
                height = height + 24;
            end
        case "field"
            if node.Configuration.Kind == "readonly"
                height = labkit.app.internal.native.NativeAdapterValues.readonlyHeight( ...
                    node.Configuration.Value, policy.ReadonlyDefaultWidth, ...
                    policy.ReadonlyFontSize);
            elseif node.Configuration.Kind == "logical"
                height = labkit.app.internal.native.NativeAdapterValues.estimatedControlHeight( ...
                    node.Configuration.Label, 32, 3, ...
                    policy.FieldHeight);
            else
                height = labkit.app.internal.native.NativeAdapterValues.estimatedControlHeight( ...
                    node.Configuration.Label, 30, 2, ...
                    policy.FieldHeight);
            end
        case "rangeField"
            height = policy.FieldHeight + 26;
        case "panner"
            height = policy.FieldHeight;
        case {"section", "group"}
            if node.Kind == "group" && obj.isGrowableTabChild(node)
                height = "1x";
                return
            end
            children = obj.nodes(node.ChildIds);
            childHeights = zeros(1, numel(children));
            for k = 1:numel(children)
                candidate = obj.preferredRowHeight(children(k));
                if ischar(candidate) || isstring(candidate)
                    candidate = policy.FileListNoStatusHeight;
                end
                childHeights(k) = candidate;
            end
            layout = obj.groupLayout(node);
            if node.Kind == "section" && ...
                    ~obj.sectionDrawsOwnTitle(node) && ...
                    isscalar(children)
                height = childHeights(1) + ...
                    policy.UntitledSectionChromeHeight;
            elseif layout == "actions"
                [rows, ~] = obj.actionGridSize(node);
                height = rows * policy.ButtonHeight + ...
                    max(0, rows - 1) * policy.ContentSpacing + ...
                    policy.GroupChromeHeight;
                owner = obj.owningNode(node.Id);
                if ~isempty(owner) && owner.Kind == "workspacePage" && owner.Configuration.Heading ~= ""
                    height = height + 8;
                end
            elseif layout == "horizontal"
                height = max(childHeights, [], "omitnan") + ...
                    policy.GroupChromeHeight;
                owner = obj.owningNode(node.Id);
                if ~isempty(owner) && owner.Kind == "workspacePage" && owner.Configuration.Heading ~= ""
                    height = height + 8;
                end
            else
                chrome = policy.SectionChromeHeight;
                if node.Kind == "group" && strlength(node.Configuration.Title) == 0
                    chrome = policy.GroupChromeHeight;
                end
                height = sum(childHeights) + ...
                    max(0, numel(children) - 1) * ...
                    policy.ContentSpacing + chrome;
            end
        otherwise
            height = "fit";
    end
end
