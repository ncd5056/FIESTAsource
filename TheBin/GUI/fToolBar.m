function fToolBar(func,varargin)
switch func
    case 'Cursor'
        ToolCursor(varargin{1});
    case 'Pan'
        ToolPan(varargin{1});
    case 'ZoomIn'
        ToolZoomIn(varargin{1});
    case 'Region'
        ToolRegion(varargin{1});
    case 'RectRegion'
        ToolRectRegion(varargin{1});
    case 'NormImage'
        ToolNormImage(varargin{1});
    case 'ThreshImage'
        ToolThreshImage(varargin{1});
    case 'RedGreenImage'
        ToolRedGreenImage(varargin{1});
end

function ToolCursor(hMainGui)
set(hMainGui.ToolBar.ToolCursor,'State','on');
set(hMainGui.ToolBar.ToolPan,'State','off');
set(hMainGui.ToolBar.ToolZoomIn,'State','off');
set(hMainGui.ToolBar.ToolRegion,'State','off');
set(hMainGui.ToolBar.ToolRectRegion,'State','off');
hMainGui.Values.CursorDownPos(:)=0;
hMainGui.Values.CursorDownPos(:)=0;
hMainGui.CursorMode='Normal';
set(hMainGui.fig,'pointer','arrow');
setappdata(0,'hMainGui',hMainGui);
fRightPanel('AllToolsOff',hMainGui);
hMainGui=getappdata(0,'hMainGui');
SetZoom(hMainGui);

function ToolPan(hMainGui)
global PanInfo;
if isempty(PanInfo)
    fMsgDlg({'You can only use the pan function','while pressing down the scroll wheel','or the left and right button simutaneously'},'warn');    
    set(hMainGui.ToolBar.ToolPan,'State','off');
    fShared('ReturnFocus');
end

function ToolZoomIn(hMainGui)
global ZoomInfo;
if isempty(ZoomInfo)
    fMsgDlg({'You can only use the zoom function','by scrolling the mouse wheel up and down '},'warn');    
    set(hMainGui.ToolBar.ToolZoomIn,'State','off');
    fShared('ReturnFocus');
end

function ToolRegion(hMainGui)
global Stack;
if ~isempty(Stack)
    set(hMainGui.ToolBar.ToolCursor,'State','off');
    set(hMainGui.ToolBar.ToolPan,'State','off');
    set(hMainGui.ToolBar.ToolZoomIn,'State','off');
    set(hMainGui.ToolBar.ToolRegion,'State','on');
    set(hMainGui.ToolBar.ToolRectRegion,'State','off');
    hMainGui.Values.CursorDownPos(:)=0;
    hMainGui.CursorMode='Region';
    setappdata(0,'hMainGui',hMainGui);
    fRightPanel('AllToolsOff',hMainGui);
    hMainGui=getappdata(0,'hMainGui');
    SetZoom(hMainGui);
else
    set(hMainGui.ToolBar.ToolRegion,'State','off');
end


function ToolRectRegion(hMainGui)
global Stack;
if ~isempty(Stack)
    set(hMainGui.ToolBar.ToolCursor,'State','off');
    set(hMainGui.ToolBar.ToolPan,'State','off');
    set(hMainGui.ToolBar.ToolZoomIn,'State','off');
    set(hMainGui.ToolBar.ToolRegion,'State','off');
    set(hMainGui.ToolBar.ToolRectRegion,'State','on');
    hMainGui.Values.CursorDownPos(:)=0;
    hMainGui.CursorMode='RectRegion';
    setappdata(0,'hMainGui',hMainGui);
    fRightPanel('AllToolsOff',hMainGui);
    hMainGui=getappdata(0,'hMainGui');
    SetZoom(hMainGui);
else
    set(hMainGui.ToolBar.ToolRectRegion,'State','off');
end

function ToolNormImage(hMainGui)
global Stack;
if ~isempty(Stack)
    set(hMainGui.ToolBar.ToolNormImage,'State','on');
    set(hMainGui.ToolBar.ToolThreshImage,'State','off');
    set(hMainGui.Menu.mZProjection,'Enable','on');
    if strcmp(get(hMainGui.ToolBar.ToolRedGreenImage,'State'),'on')==1
        if strcmp(get(hMainGui.LeftPanel.pRedThresh.panel,'Visible'),'on')==1
            fLeftPanel('RedNormPanel',hMainGui);
        else
            fLeftPanel('GreenNormPanel',hMainGui);
        end
    else
        fLeftPanel('NormPanel',hMainGui);
    end
else
    set(hMainGui.ToolBar.ToolNormImage,'State','off');
end

function ToolThreshImage(hMainGui)
global Stack;
if ~isempty(Stack)
    set(hMainGui.ToolBar.ToolNormImage,'State','off');
    set(hMainGui.ToolBar.ToolThreshImage,'State','on');
    set(hMainGui.Menu.mZProjection,'Enable','off');
    if strcmp(get(hMainGui.ToolBar.ToolRedGreenImage,'State'),'on')==1
        if strcmp(get(hMainGui.LeftPanel.pRedNorm.panel,'Visible'),'on')==1
            fLeftPanel('RedThreshPanel',hMainGui);
        else
            fLeftPanel('GreenThreshPanel',hMainGui);
        end
    else
        fLeftPanel('ThreshPanel',hMainGui);
    end
else
    set(hMainGui.ToolBar.ToolThreshImage,'State','off');
end

function ToolRedGreenImage(hMainGui)
global Stack;
if ~isempty(Stack)
    set(hMainGui.Menu.mZProjection,'Enable','off');
    if strcmp(get(hMainGui.ToolBar.ToolRedGreenImage,'State'),'on')==1
        if strcmp(get(hMainGui.ToolBar.ToolNormImage,'State'),'on')==1
            fLeftPanel('RedNormPanel',hMainGui);
        else
            fLeftPanel('RedThreshPanel',hMainGui);
        end
    else
        if strcmp(get(hMainGui.ToolBar.ToolNormImage,'State'),'on')==1
            fLeftPanel('NormPanel',hMainGui);
        else
            fLeftPanel('ThreshPanel',hMainGui);
        end
    end
else
    set(hMainGui.ToolBar.ToolRedGreenImage,'State','off');
end

function SetZoom(hMainGui)
Zoom=hMainGui.ZoomView;
if ~isempty(Zoom.globalXY)
    Zoom.currentXY=get(hMainGui.MidPanel.aView,{'xlim','ylim'});
    x_total=Zoom.globalXY{1}(2)-Zoom.globalXY{1}(1);
    x_current=Zoom.currentXY{1}(2)-Zoom.currentXY{1}(1);
    Zoom.level=round(-log(x_current/x_total)*8);
    hMainGui.ZoomView=Zoom;
end
Zoom=hMainGui.ZoomKymo;
if ~isempty(Zoom.globalXY)
    Zoom.currentXY=get(hMainGui.RightPanel.pTools.aKymoGraph,{'xlim','ylim'});
    x_total=Zoom.globalXY{1}(2)-Zoom.globalXY{1}(1);
    x_current=Zoom.currentXY{1}(2)-Zoom.currentXY{1}(1);
    Zoom.level=round(-log(x_current/x_total)*8);
    hMainGui.ZoomKymo=Zoom;
end
setappdata(0,'hMainGui',hMainGui);