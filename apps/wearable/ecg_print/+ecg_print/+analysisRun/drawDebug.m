function drawDebug(axesById,model)
%DRAWDEBUG Processing stages and per-beat results on a shared time axis.
ids=["raw","template","residual","noise","metricNoise","beatNoise","beatPeak","beatSnr"];
axes=arrayfun(@(id)axesById.(id),ids);
linkaxes(axes,'off');
for j=1:8
    ax=axes(j);xlim(ax,model.limits);legend(ax,'off');delete(allchild(ax));cla(ax);hold(ax,'on');
    ax.Layout.Row=j;ax.Visible='on';ax.YLimMode='auto';ax.Toolbar.Visible='on';
    if model.overlay && j>1 && j<=5
        ax.Visible='off';ax.Toolbar.Visible='off';title(ax,'');xlabel(ax,'');ylabel(ax,'');
    end
end
if model.overlay,axes(1).Layout.Row=[1 5];end
% MATLAB default palette: blue ECG, orange-red template, cyan residual,
% green extracted noise, purple centered noise.
colors=[0 .447 .741;.850 .325 .098;.301 .745 .933;.466 .674 .188; ...
    .494 .184 .556;.494 .184 .556;0 .447 .741;.466 .674 .188];
for j=1:8
    s=model.(ids(j));ax=axes(j);
    if model.overlay && j<=5,ax=axes(1);end
    order=1:size(s.values,2);
    if j==2 && numel(order)==2,order=[2 1];end
    for c=order
        style='-';color=colors(j,:);marker='none';
        if j>5,marker='.';end
        if j==2 && c==1,style='--';end
        if j==2 && c==2,color=colors(1,:);end
        if model.overlay && j==3,style=':';end
        plot(ax,s.time,s.values(:,c),'LineWidth',1.15,'LineStyle',style, ...
            'Color',color,'Marker',marker,'DisplayName',s.names(c));
    end
    title(ax,s.title,'FontWeight','normal','FontSize',11,'HorizontalAlignment','left');
    ax.Title.Units='normalized';ax.Title.Position=[0 1.02 0];
    xlabel(ax,'');ylabel(ax,s.unit);grid(ax,'on');ax.GridAlpha=.12;
    if j==8
        xlabel(ax,'ROI time (s)');ax.XTickLabelMode='auto';
    else
        ax.XTickLabel=[];
    end
end
for ax=axes,hold(ax,'off');end
if model.overlay
    title(axes(1),'Signal chain overlay');
    if ~isempty(axes(1).Children),legend(axes(1),'show','Location','southoutside','Orientation','horizontal','NumColumns',3,'Interpreter','none');end
else
    % Inline color labels in titles leave equal plot heights and clear traces.
    yline(axes(5),0,':','Color',[.65 .65 .65],'HandleVisibility','off');
    values=[model.residual.values(:);model.noise.values(:)];
    values=values(isfinite(values));
    if ~isempty(values)
        low=min(values);high=max(values);margin=max(eps,.05*max(high-low,eps));
        ylim(axes(3),[low-margin high+margin]);ylim(axes(4),[low-margin high+margin]);
        % Shade only the discarded source interval, not interpolated noise.
        ax=axes(3);hold(ax,'on');
        for time=model.rTimes(:)'
            bounds=[max(model.limits(1),time-.04),min(model.limits(2),time+.04)];
            if bounds(2)<=bounds(1),continue;end
            patch(ax,bounds([1 2 2 1]),[low-margin low-margin high+margin high+margin], ...
                [.65 .65 .65],'FaceAlpha',.15,'EdgeColor','none', ...
                'HandleVisibility','off','HitTest','off','PickableParts','none');
        end
        hold(ax,'off');
    end

end
linkaxes(axes,'x');xlim(axes(1),model.limits);
end
