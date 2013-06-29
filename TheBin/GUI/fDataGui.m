function fDataGui(func,varargin)
switch (func)
    case 'Create'
        try
            Create(varargin{1},varargin{2});
        catch
            return;
        end
    case 'Draw'
        Draw(varargin{1},varargin{2});
    case 'PlotXY'
        PlotXY(varargin{1});
    case 'PlotDisTime'
        PlotDisTime(varargin{1});
    case 'PlotIntLen'
        PlotIntLen(varargin{1});
    case 'PlotVelTim'
        PlotVelTim(varargin{1});
    case 'Delete'
        Delete(varargin{1});
    case 'Switch'
        Switch(varargin{1});        
    case 'Split'
        Split(varargin{1});          
    case 'SelectAll'
        SelectAll(varargin{1});          
    case 'Drift'
        Drift(varargin{1});
    case 'XAxisList'
        XAxisList(varargin{1});        
    case 'CheckYAxis2'
        CheckYAxis2(varargin{1});              
    case 'bToggleToolCursor'
        bToggleToolCursor(varargin{1});  
    case 'bToolPan'
        bToolPan(varargin{1});
    case 'bToolZoomIn'
        bToolZoomIn(varargin{1});
    case 'Export'
        Export(varargin{1});
end

function hDataGui = Create(Type,idx)
global Molecule;
global Filament;
hDataGui=getappdata(0,'hDataGui');
hDataGui.idx=idx;
hDataGui.Type=Type;
if strcmp(Type,'Molecule')==1
    Object=Molecule(idx);
else
    Object=Filament(idx);
end
h=findobj('Tag','hDataGui');

[lXaxis,lYaxis]=CreatePlotList(Object,Type);

if isempty(h)
    hDataGui.fig = figure('Units','normalized','DockControls','off','IntegerHandle','off','MenuBar','none','Name',Object.Name,...
                          'NumberTitle','off','HandleVisibility','callback','Tag','hDataGui',...
                          'Visible','off','Resize','off','WindowStyle','normal');
                      
    fPlaceFig(hDataGui.fig,'big');
    
    if ispc
        set(hDataGui.fig,'Color',[236 233 216]/255);
    end
    
    c = get(hDataGui.fig,'Color');

    hDataGui.pPlotPanel = uipanel('Parent',hDataGui.fig,'Position',[0.35 0.55 0.625 0.4],'Tag','PlotPanel','BackgroundColor','white');
    
    hDataGui.aPlot = axes('Parent',hDataGui.pPlotPanel,'OuterPosition',[0 0 1 1],'Tag','Plot','NextPlot','add','TickDir','out','Layer','top',...
                          'XLimMode','manual','YLimMode','manual');
    hDataGui.aPlot2 = axes('Parent',hDataGui.pPlotPanel,'OuterPosition',[0 0 1 1],'Tag','Plot2','NextPlot','add','TickDir','out','Layer','top',...
                          'XLimMode','manual','YLimMode','manual');
    
    columnname = {'','','','','','','','',''};
    if mean(Object.Results(2:end,2)-Object.Results(1:end-1,2))<0.1
        columnformat = {'logical','numeric','bank','bank','bank','bank','bank', 'bank', 'bank'};
    else
        columnformat = {'logical','numeric','short','bank','bank','bank','bank', 'bank', 'bank'};
    end
    columneditable = logical([ 1, 0, 0, 0, 0, 0, 0, 0, 0]);
    
    hDataGui.tTable = uitable('Parent',hDataGui.fig,'Units','normalized','Position',[0.025 0.025 0.95 0.475],'Tag','tTable','Enable','on',...            
                              'ColumnName', columnname,'ColumnFormat', columnformat,'ColumnEditable', columneditable,'RowName',[]);

    hDataGui.tName = uicontrol('Parent',hDataGui.fig,'Units','normalized','FontSize',10,'FontWeight','bold',...
                              'HorizontalAlignment','left','Position',[0.025 0.96 0.3 0.02],...
                              'String',Object.Name,'Style','text','Tag','tName','BackgroundColor',c);

    hDataGui.tFile = uicontrol('Parent',hDataGui.fig,'Units','normalized','FontSize',8,'FontAngle','italic',...
                              'HorizontalAlignment','left','Position',[0.025 0.90 0.3 0.055],...
                              'String',Object.File,'Style','text','Tag','tFile','BackgroundColor',c);

    hDataGui.tIndex = uicontrol('Parent',hDataGui.fig,'Units','normalized','FontSize',10,'HorizontalAlignment','left',...
                                'Position',[0.025 0.88 0.05 0.02],'String','Index:','Style','text','Tag','tIndex','BackgroundColor',c);

    hDataGui.tIndexValue = uicontrol('Parent',hDataGui.fig,'Units','normalized','FontSize',10,'HorizontalAlignment','right',...
                                'Position',[0.1 0.88 0.05 0.02],'String',num2str(idx),'Style','text','Tag','tIndexValue','BackgroundColor',c);                        

    hDataGui.cDrift = uicontrol('Parent',hDataGui.fig,'Units','normalized','Callback','fDataGui(''Drift'',getappdata(0,''hDataGui''));',...
                                'Position',[0.025 0.855 0.2 0.02],'String','Correct for Drift','Style','checkbox','BackgroundColor',c,'Tag','cDrift','Value',Object.Drift);

    hDataGui.gColor = uibuttongroup('Title','Color','Tag','bColor','Units','normalized','Position',[0.025 0.75 0.3 0.1],'BackgroundColor',c);

    hDataGui.rBlue = uicontrol('Parent',hDataGui.gColor,'Units','normalized','Position',[0.05 0.7 0.4 0.2],...
                               'String','Blue','Style','radiobutton','BackgroundColor',c,'Tag','rBlue','UserData',[0 0 1]);

    hDataGui.rGreen = uicontrol('Parent',hDataGui.gColor,'Units','normalized','Position',[0.05 0.4 0.4 0.2],...
                                'String','Green','Style','radiobutton','BackgroundColor',c,'Tag','rGreen','UserData',[0 1 0]);

    hDataGui.rRed = uicontrol('Parent',hDataGui.gColor,'Units','normalized','Position',[0.05 0.1 0.4 0.2],...
                              'String','Red','Style','radiobutton','BackgroundColor',c,'Tag','rRed','UserData',[1 0 0]);

    hDataGui.rMagenta = uicontrol('Parent',hDataGui.gColor,'Units','normalized','Position',[0.55 0.7 0.4 0.2],...
                               'String','Magenta','Style','radiobutton','BackgroundColor',c,'Tag','rMagenta','UserData',[1 0 1]);

    hhDataGui.rCyan = uicontrol('Parent',hDataGui.gColor,'Units','normalized','Position',[0.55 0.4 0.4 0.2],...
                                  'String','Cyan','Style','radiobutton','BackgroundColor',c,'Tag','rCyan','UserData',[0 1 1]);

    hDataGui.rPink = uicontrol('Parent',hDataGui.gColor,'Units','normalized','Position',[0.55 0.1 0.4 0.2],...
                                 'String','Pink','Style','radiobutton','BackgroundColor',c,'Tag','rPink ','UserData',[1 0.5 0.5]);

    set(hDataGui.gColor,'SelectionChangeFcn',@selcbk);

    set(hDataGui.gColor,'SelectedObject',findobj('UserData',Object.Color,'Parent',hDataGui.gColor));

    hDataGui.pPlot = uipanel('Parent',hDataGui.fig,'Title','Plot','Tag','gPlot','Position',[0.025 0.55 0.3 0.2],'BackgroundColor',c);

    hDataGui.tXaxis = uicontrol('Parent',hDataGui.pPlot,'Units','normalized','Style','text','FontSize',8,'Position',[0.05 0.8 0.33 0.15],...
                                'HorizontalAlignment','left','String','X Axis:','Tag','lXaxis','BackgroundColor',c);

    hDataGui.lXaxis = uicontrol('Parent',hDataGui.pPlot,'Units','normalized','Callback','fDataGui(''XAxisList'',getappdata(0,''hDataGui''));',...
                                'Style','popupmenu','FontSize',8,'Position',[0.4 0.8 0.55 0.18],'String',lXaxis.list,'Tag','lXaxis','UserData',lXaxis,'BackgroundColor','white');

    hDataGui.tYaxis = uicontrol('Parent',hDataGui.pPlot,'Units','normalized','Style','text','FontSize',10,'Position',[0.05 0.6 0.33 0.15],...
                                'HorizontalAlignment','left','String','Y Axis (left):','Tag','lYaxis','BackgroundColor',c);

    hDataGui.lYaxis = uicontrol('Parent',hDataGui.pPlot,'Units','normalized','Callback','fDataGui(''Draw'',getappdata(0,''hDataGui''),0);',...
                                'Style','popupmenu','FontSize',8,'Position',[0.4 0.6 0.55 0.18],'String',lYaxis(1).list,'Tag','lYaxis','UserData',lYaxis,'BackgroundColor','white');                        

    hDataGui.cYaxis2 = uicontrol('Parent',hDataGui.pPlot,'Units','normalized','Callback','fDataGui(''CheckYAxis2'',getappdata(0,''hDataGui''));',...
                                'Position',[0.05 0.46 0.9 0.12],'String','Add second plot','Style','checkbox','BackgroundColor',c,'Tag','cYaxis2','Value',0,'Enable','off');

    hDataGui.tYaxis2 = uicontrol('Parent',hDataGui.pPlot,'Units','normalized','Style','text','FontSize',8,'Position',[0.05 0.26 0.33 0.15],...
                                'HorizontalAlignment','left','String','Y Axis (right):','Tag','lYaxis','Enable','off','BackgroundColor',c);

    hDataGui.lYaxis2 = uicontrol('Parent',hDataGui.pPlot,'Units','normalized','Callback','fDataGui(''Draw'',getappdata(0,''hDataGui''),0);',...
                                'Style','popupmenu','FontSize',8,'Position',[0.4 0.26 0.55 0.18],'String',lYaxis(1).list,'Tag','lYaxis2','UserData',lYaxis,'Enable','off','BackgroundColor','white');                        

    hDataGui.bExport = uicontrol('Parent',hDataGui.pPlot,'Units','normalized','Callback','fDataGui(''Export'',getappdata(0,''hDataGui''));',...
                                 'FontSize',10,'Position',[0.05 0.1 0.9 0.14],'String','Export','Tag','bExport','UserData','Export');

    hDataGui.tPrint = uicontrol('Parent',hDataGui.pPlot,'Units','normalized','Style','text','BackgroundColor',c,...
                                'FontSize',8,'Position',[0.05 0.01 0.9 0.08],'String','(for printing use export to PDF)','Tag','tPrint');
    
    
    hDataGui.bSelectAll = uicontrol('Parent',hDataGui.fig,'Units','normalized','Callback','fDataGui(''SelectAll'',getappdata(0,''hDataGui''));',...
                             'Position',[0.025 0.505 0.1 0.025],'String','Select all','Tag','bSelectAll','UserData',1);                    
                         
    hDataGui.bClear = uicontrol('Parent',hDataGui.fig,'Units','normalized','Callback','fDataGui(''SelectAll'',getappdata(0,''hDataGui''));',...
                             'Position',[0.13 0.505 0.1 0.025],'String','Clear selection','Tag','bClear','UserData',0);                         
    
    hDataGui.bDelete = uicontrol('Parent',hDataGui.fig,'Units','normalized','Callback','fDataGui(''Delete'',getappdata(0,''hDataGui''));',...
                             'Position',[0.35 0.515 0.185 0.025],'String','Delete','Tag','bDelete');
                         
    hDataGui.bSplit = uicontrol('Parent',hDataGui.fig,'Units','normalized','Callback','fDataGui(''Split'',getappdata(0,''hDataGui''));',...
                             'Position',[0.565 0.515 0.185 0.025],'String','Create new track','Tag','bSplit');
   
    hDataGui.bSwitch = uicontrol('Parent',hDataGui.fig,'Units','normalized','Callback','fDataGui(''Switch'',getappdata(0,''hDataGui''));',...
                                'Position',[0.78 0.515 0.185 0.025],'String','Switch MT orientation','Tag','bDelete');
                            
    hDataGui.tFrame = uicontrol('Parent',hDataGui.fig,'Units','normalized','FontSize',10,'HorizontalAlignment','left',...
                             'Position',[0.85 0.96 0.05 0.02],'String','Frame:','Style','text','Tag','tFrame','BackgroundColor',c);

    hDataGui.tFrameValue = uicontrol('Parent',hDataGui.fig,'Units','normalized','FontSize',10,'HorizontalAlignment','right',...
                                  'Position',[0.9 0.96 0.05 0.02],'String','','Style','text','Tag','tFrameValue','BackgroundColor',c);

    set(hDataGui.fig, 'WindowButtonMotionFcn', @UpdateCursor);
    set(hDataGui.fig, 'WindowButtonUpFcn',@ButtonUp);
    set(hDataGui.fig, 'WindowButtonDownFcn',@ButtonDown);
    set(hDataGui.fig, 'KeyPressFcn',@KeyPress);
    set(hDataGui.fig, 'KeyReleaseFcn',@KeyRelease);
    set(hDataGui.fig, 'CloseRequestFcn',@Close);
    set(hDataGui.fig, 'WindowScrollWheelFcn',@Scroll);  
    set(hDataGui.tTable, 'CellEditCallback',@Select);
    set(hDataGui.tTable, 'CellSelectionCallback',@ReturnFocus);
else
    setappdata(hDataGui.fig,'Object',Object);
    set(hDataGui.fig,'Name',Object.Name,'WindowStyle','normal','Visible','on');
    set(hDataGui.tName,'String',Object.Name);
    set(hDataGui.tFile,'String',Object.File);
    set(hDataGui.tIndexValue,'String',num2str(idx));
    set(hDataGui.cDrift,'Value',Object.Drift);
    set(hDataGui.gColor,'SelectedObject',findobj('UserData',Object.Color,'Parent',hDataGui.gColor));

    x=get(hDataGui.lXaxis,'Value');
    if x>length(lXaxis.list)
        set(hDataGui.lXaxis,'Value',length(lXaxis.list));            
    end
    set(hDataGui.lXaxis,'String',lXaxis.list,'UserData',lXaxis);    
    set(hDataGui.lYaxis,'UserData',lYaxis);    
    set(hDataGui.lYaxis2,'UserData',lYaxis);        
    if x==length(lXaxis.list)
        CreateHistograms(hDataGui);
    end
    figure(hDataGui.fig);
end
hDataGui.CursorDownPos = [0 0];
hDataGui.Zoom = struct('currentXY',[],'globalXY',[],'level',[],'aspect',GetAxesAspectRatio(hDataGui.aPlot));
hDataGui.SelectRegion = struct('X',[],'Y',[],'plot',[]);
hDataGui.ZoomRegion = struct('X',[],'Y',[],'plot',[]);
hDataGui.CursorMode='Normal';

CreateTable(hDataGui,[num2cell(false(size(Object.Results,1),1)) num2cell(Object.Results(:,1:8))]);
Check = false(size(Object.Results,1),1);

setappdata(0,'hDataGui',hDataGui);
setappdata(hDataGui.fig,'Object',Object);
setappdata(hDataGui.fig,'Check',Check);
try
    XAxisList(hDataGui);
catch
    delete(hDataGui.fig);
    Create(Type,idx);
end

function CreateTable(hDataGui,data)
set(hDataGui.tTable,'Units','pixels');
Pos = get(hDataGui.tTable,'Position');
set(hDataGui.tTable,'Units','normalized');
if strcmp(hDataGui.Type,'Molecule')
    columnname = {'Select','Frame','Time[sec]','XPosition[nm]','YPosition[nm]','Distance[nm]','FWHM[nm]','Amplitude[counts]','Position Error[nm]'};
else
    columnname = {'Select','Frame','Time[sec]','XPosition[nm]','YPosition[nm]','Distance[nm]','Length[nm]','Amplitude[counts]','Orientation[rad]'};
end
columnweight = [ 0.5, 0.8, 0.8, 1.3, 1.3, 1.3, 1.3, 1.3, 1.5];
columnwidth = fix(columnweight*Pos(3)/sum(columnweight));
columnwidth(9) = columnwidth(9) + fix(Pos(3))-sum(columnwidth) - 2;
if size(data,1)>22
    columnwidth(9) = columnwidth(9) - 17;
end
set(hDataGui.tTable,'Data',data,'ColumnName',columnname,'ColumnWidth',num2cell(columnwidth));

function selcbk(hObject,eventdata) %#ok<INUSD>
global Molecule;
global Filament;
global KymoTrackMol;
global KymoTrackFil;
hDataGui=getappdata(0,'hDataGui');
hMainGui=getappdata(0,'hMainGui');
color=get(get(hDataGui.gColor,'SelectedObject'),'UserData');
Object=getappdata(hDataGui.fig,'Object');
Object.Color=color;
setappdata(hDataGui.fig,'Object',Object);
if strcmp(hDataGui.Type,'Molecule')
    Molecule(hDataGui.idx)=Object;
    try
        set(Molecule(hDataGui.idx).PlotHandles(1),'Color',color);
        k=findobj('Parent',hMainGui.MidPanel.aView,'-and','UserData',Molecule(hDataGui.idx).Name);
        set(k,'Color',color);           
        k=find([KymoTrackMol.Index]==hDataGui.idx);
        if ~isempty(k)
            set(KymoTrackMol(k).PlotHandles(1),'Color',color);   
        end
    catch
    end
else
    Filament(hDataGui.idx)=Object;
    try
        set(Filament(hDataGui.idx).PlotHandles(1),'Color',color);
        k=findobj('Parent',hMainGui.MidPanel.aView,'-and','UserData',Microtuble(hDataGui.idx).Name);
        set(k,'Color',color);           
        k=find([KymoTrackFil.Index]==hDataGui.idx);
        if ~isempty(k)
            set(KymoTrackFil(k).PlotHandles(1),'Color',color);            
        end
    catch
    end
end
ReturnFocus([],[]);

function Export(hDataGui)
fExportDataGui('Create',hDataGui.Type,hDataGui.idx);
ReturnFocus([],[]);

function Draw(hDataGui,ax)
%get object data
Object=getappdata(hDataGui.fig,'Object');
%save current view
xy=get(hDataGui.aPlot,{'xlim','ylim'});
xy2=get(hDataGui.aPlot2,{'xlim','ylim'});

%get plot colums
x=get(hDataGui.lXaxis,'Value');
XList=get(hDataGui.lXaxis,'UserData');
XPlot=XList.data{x};

y=get(hDataGui.lYaxis,'Value');
YList=get(hDataGui.lYaxis,'UserData');
if ~isempty(XPlot)
    YPlot=YList(x).data{y};
else
    XPlot=YList(x).data{y}(:,1);
    YPlot=YList(x).data{y}(:,2);
    XList.list{x}=YList(x).list{y};
    XList.units{x}=YList(x).units{y};
    YList(x).list{y}='number of data points';    
    YList(x).units{y}='';
end

delete(hDataGui.aPlot2);                  
hDataGui.aPlot2 = axes('Parent',hDataGui.pPlotPanel,'OuterPosition',[0 0 1 1],'NextPlot','add','TickDir','out',...
                      'XLimMode','manual','YLimMode','manual');     
                  
delete(hDataGui.aPlot);
hDataGui.aPlot = axes('Parent',hDataGui.pPlotPanel,'OuterPosition',[0 0 1 1],'NextPlot','add','TickDir','out',...
                      'XLimMode','manual','YLimMode','manual'); 
                  
set(0,'CurrentFigure',hDataGui.fig);                  
setappdata(0,'hDataGui',hDataGui);                 
hold on     
xscale=1;
yscale=1;
yscale2=1;
if strcmp(XList.units{x},'[nm]') && (max(YPlot)-min(YPlot))>5000
    xscale=1000;
    XList.units{x}='[µm]';
    if strcmp(YList(x).units{y},'[nm]')
        yscale=1000;
        YList(x).units{y}='[µm]';
    end
end
if strcmp(YList(x).units{y},'[nm]') && (max(YPlot)-min(YPlot))>5000
    yscale=1000;
    YList(x).units{y}='[µm]';
    if strcmp(XList.units{x},'[nm]')
        xscale=1000;
        XList.units{x}='[µm]';    
    end
end
if x<length(XList.data)
    FilXY = [];
    if x==1
        Dis=norm([Object.Results(1,3)-Object.Results(end,3) Object.Results(1,4)-Object.Results(end,4)]);     
        if strcmp(hDataGui.Type,'Filament')
            FilXY=cell(1,4);
            lData=length(Object.Data);
            VecX=zeros(lData,2);
            VecY=zeros(lData,2);
            VecU=zeros(lData,2);
            VecV=zeros(lData,2);
            Length=mean(Object.Results(:,6)); 
            for i=1:lData
                n=size(Object.Data{i},1);     
                if n>1
                    line((Object.Data{i}(:,1)-min(XPlot))/xscale,(Object.Data{i}(:,2)-min(YPlot))/yscale,'Color','red','LineStyle','-','Marker','none');
                    if Dis<=2*Object.PixelSize
                        VecX(i,:)=[Object.Data{i}(ceil(n/4),1) Object.Data{i}(fix(3*n/4),1)]-min(XPlot);
                        VecY(i,:)=[Object.Data{i}(ceil(n/4),2) Object.Data{i}(fix(3*n/4),2)]-min(YPlot);                    
                        VecU(i,:)=[Object.Data{i}(ceil(n/4)+1,1) Object.Data{i}(fix(3*n/4)+1,1)]-min(XPlot);
                        VecV(i,:)=[Object.Data{i}(ceil(n/4)+1,2) Object.Data{i}(fix(3*n/4)+1,2)]-min(YPlot);
                    end
                    FilXY{1} = min([(Object.Data{i}(:,1)'-min(XPlot)) FilXY{1}]);
                    FilXY{2} = max([(Object.Data{i}(:,1)'-min(XPlot)) FilXY{2}]);                    
                    FilXY{3} = min([(Object.Data{i}(:,2)'-min(YPlot)) FilXY{3}]);
                    FilXY{4} = max([(Object.Data{i}(:,2)'-min(YPlot)) FilXY{4}]);                    
                end
            end
            if Dis<=2*Object.PixelSize
                VecX=mean(VecX);
                VecY=mean(VecY);                
                VecU=mean(VecU);
                VecV=mean(VecV);                            
                U=(VecU-VecX)./sqrt((VecU-VecX).^2+(VecV-VecY).^2);
                V=(VecV-VecY)./sqrt((VecU-VecX).^2+(VecV-VecY).^2);                
                fill([VecX(1)+Length/20*U(1) VecX(1)+Length/40*V(1) VecX(1)-Length/40*V(1)]/xscale,[VecY(1)+Length/20*V(1) VecY(1)-Length/40*U(1) VecY(1)+Length/40*U(1)]/yscale,'r','EdgeColor','none');
                if lData>1
                    fill([VecX(2)+Length/20*U(2) VecX(2)+Length/40*V(2) VecX(2)-Length/40*V(2)]/xscale,[VecY(2)+Length/20*V(2) VecY(2)-Length/40*U(2) VecY(2)+Length/40*U(2)]/yscale,'r','EdgeColor','none');                
                end
            end
        end
        if Dis>2*Object.PixelSize     
            n(1) = find(Object.Results(:,5)<Dis/4,1,'last');
            n(2) = find(Object.Results(:,5)<Dis/2,1,'last');
            n(3) = find(Object.Results(:,5)<3*Dis/4,1,'last');
            n(4) = size(Object.Results,1);     
            VecX=[Object.Results(n(1),3) Object.Results(n(2),3) Object.Results(n(3),3)]-min(XPlot);
            VecY=[Object.Results(n(1),4) Object.Results(n(2),4) Object.Results(n(3),4)]-min(YPlot);                    
            VecU=[mean(Object.Results(n(1)+1:n(2),3)) mean(Object.Results(n(2)+1:n(3),3)) mean(Object.Results(n(3)+1:n(4),3))]-min(XPlot);
            VecV=[mean(Object.Results(n(1)+1:n(2),4)) mean(Object.Results(n(2)+1:n(3),4)) mean(Object.Results(n(3)+1:n(4),4))]-min(YPlot);
            U=(VecU-VecX)./sqrt((VecU-VecX).^2+(VecV-VecY).^2);
            V=(VecV-VecY)./sqrt((VecU-VecX).^2+(VecV-VecY).^2);    
            for m = 1:3
                fill([VecX(m)+Dis/15*U(m) VecX(m)+Dis/30*V(m) VecX(m)-Dis/30*V(m)]/xscale,[VecY(m)+Dis/15*V(m) VecY(m)-Dis/30*U(m) VecY(m)+Dis/30*U(m)]/yscale,[0.8 0.8 0.8],'EdgeColor','none');
            end   
        end
        
        XPlot=XPlot-min(XPlot);
        YPlot=YPlot-min(YPlot);        
    end

    %get checked table entries
    Check = getappdata(hDataGui.fig,'Check');
    k=find(Check==1);

    if strcmp(get(hDataGui.cYaxis2,'Enable'),'on') && get(hDataGui.cYaxis2,'Value')

        y2=get(hDataGui.lYaxis2,'Value');
        YList2=get(hDataGui.lYaxis2,'UserData');    
        YPlot2=YList2(x).data{y2};

        if strcmp(YList2(x).units{y2},'[nm]') && max(YPlot2)-min(YPlot2)>5000
            yscale2=1000;
            YList2(x).units{y2}='[µm]';
        end
        delete(hDataGui.aPlot2);
        [AX,hDataGui.DataPlot,hDataGui.DataPlot2]=plotyy(hDataGui.aPlot,XPlot/xscale,YPlot/yscale,XPlot/xscale,YPlot2/yscale2,'plot');
        hDataGui.aPlot=AX(1);
        hDataGui.aPlot2=AX(2); 

        if k>0
            set(hDataGui.fig,'CurrentAxes',hDataGui.aPlot);
            line(XPlot(k)/xscale,YPlot(k)/yscale,'Color','green','LineStyle','none','Marker','o');
            set(hDataGui.fig,'CurrentAxes',hDataGui.aPlot2);
            line(XPlot(k)/xscale,YPlot2(k)/yscale2,'Color','green','LineStyle','none','Marker','o');        
        end

        set(hDataGui.aPlot,'TickDir','out','YTickMode','auto');
        set(hDataGui.aPlot2,'TickDir','out','YTickMode','auto');

        SetLabels(hDataGui,Object,XList,YList,YList2,x,y,y2);
        if length(XPlot)>1
            SetAxis(hDataGui.aPlot,XPlot/xscale,YPlot/yscale,x);
            SetAxis(hDataGui.aPlot2,XPlot/xscale,YPlot2/yscale2,x);
        else
            axis auto;
        end
        set(hDataGui.DataPlot,'Marker','*');
        set(hDataGui.DataPlot2,'Marker','*');
    else
        set(hDataGui.aPlot2,'Visible','off');        
        hDataGui.DataPlot=plot(hDataGui.aPlot,XPlot/xscale,YPlot/yscale,'Color','blue','LineStyle','-','Marker','*');
        if k>0
            set(hDataGui.fig,'CurrentAxes',hDataGui.aPlot);
            line(XPlot(k)/xscale,YPlot(k)/yscale,'Color','green','LineStyle','none','Marker','o');
        end
        if ~isempty(FilXY)
            XPlot=[FilXY{1} FilXY{2}];
            YPlot=[FilXY{3} FilXY{4}];
        end                
        if length(XPlot)>1
            SetAxis(hDataGui.aPlot,XPlot/xscale,YPlot/yscale,x);
            %axis auto;
        else
            axis auto;
        end
        SetLabels(hDataGui,Object,XList,YList,[],x,y,[]);
    end
else
    hDataGui.DataPlot=bar(hDataGui.aPlot,XPlot/xscale,YPlot/yscale,'BarWidth',1,'EdgeColor','black','FaceColor','blue','LineWidth',1);
    SetAxis(hDataGui.aPlot,XPlot/xscale,YPlot/yscale,NaN);
    set(hDataGui.aPlot2,'Visible','off');    
    SetLabels(hDataGui,Object,XList,YList,[],x,y,[]);
end
hold off;
if xy{1}(2)~=1&&xy{2}(2)~=1 && ax==-1
    set(hDataGui.aPlot,{'xlim','ylim'},xy);
    if strcmp(get(hDataGui.aPlot2,'Visible'),'on')
        set(hDataGui.aPlot2,{'xlim','ylim'},xy2);        
    end
else
    hDataGui.Zoom.globalXY = get(hDataGui.aPlot,{'xlim','ylim'});
    hDataGui.Zoom.currentXY = hDataGui.Zoom.globalXY;
    hDataGui.Zoom.level = 0;
end
setappdata(0,'hDataGui',hDataGui);
ReturnFocus([],[]);

function SetAxis(a,X,Y,idx)
set(a,'Units','pixel');
pos=get(a,'Position');
set(a,'Units','normalized');
if idx==1
    xy{1}=[-ceil(max(-X)) ceil(max(X))]+[-0.01 0.01]*(max(X)-min(X));
    xy{2}=[-ceil(max(-Y)) ceil(max(Y))]+[-0.01 0.01]*(max(Y)-min(Y));
else
    xy{1}=[min(X) max(X)];
    xy{2}=[min(Y) max(Y)];
end
if all(~isnan(xy{1}))&&all(~isnan(xy{2}))
    if idx==1
        lx=max(X)-min(X);
        ly=max(Y)-min(Y);
        if ly>lx
            xy{1}(2)=min(X)+lx/2+ly/2;
            xy{1}(1)=min(X)+lx/2-ly/2;
        else
            xy{2}(2)=min(Y)+ly/2+lx/2;            
            xy{2}(1)=min(Y)+ly/2-lx/2;
        end
        lx=xy{1}(2)-xy{1}(1);
        xy{1}(1)=xy{1}(1)-lx*(pos(3)/pos(4)-1)/2;
        xy{1}(2)=xy{1}(2)+lx*(pos(3)/pos(4)-1)/2;
        set(a,{'xlim','ylim'},xy,'YDir','reverse');
    else
        set(a,{'xlim','ylim'},xy,'YDir','normal');
        if isnan(idx)
            XTick=get(a,'XTick');
            s=length(XTick);
            xy{1}(1)=2*XTick(1)-XTick(2); 
            xy{1}(2)=2*XTick(s)-XTick(s-1); 
            xy{2}(1)=0;
        end
        YTick=get(a,'YTick');
        s=length(YTick);
        if YTick(1)~=0
            xy{2}(1)=2*YTick(1)-YTick(2); 
        end            
        xy{2}(2)=2*YTick(s)-YTick(s-1); 
        set(a,{'xlim','ylim'},xy,'YDir','normal');
    end
end

function SetLabels(hDataGui,Object,XList,YList,YList2,x,y,y2)
%title(hDataGui.aPlot,[Object.Name ' - ' Object.File],'Interpreter','none','Fontsize',8);
xlabel(hDataGui.aPlot,[XList(1).list{x} '  ' XList.units{x}]);
ylabel(hDataGui.aPlot,[YList(x).list{y} '  ' YList(x).units{y}]);
if ~isempty(y2)
    ylabel(hDataGui.aPlot2,[YList2(x).list{y2} '  ' YList2(x).units{y2}]);
end

function KeyPress(~,evnt)
hDataGui=getappdata(0,'hDataGui');
if strcmp(hDataGui.CursorMode,'Normal');
    switch(evnt.Key)
        case 'shift' 
            hDataGui.CursorMode='Zoom';
            CData = [NaN,NaN,NaN,NaN,1,1,1,1,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,1,1,NaN,2,NaN,2,1,1,NaN,NaN,NaN,NaN,NaN,NaN;NaN,1,2,NaN,2,1,1,NaN,2,NaN,1,NaN,NaN,NaN,NaN,NaN;NaN,1,NaN,2,NaN,1,1,2,NaN,2,1,NaN,NaN,NaN,NaN,NaN;1,NaN,2,NaN,2,1,1,NaN,2,NaN,2,1,NaN,NaN,NaN,NaN;1,2,1,1,1,1,1,1,1,1,NaN,1,NaN,NaN,NaN,NaN;1,NaN,1,1,1,1,1,1,1,1,2,1,NaN,NaN,NaN,NaN;1,2,NaN,2,NaN,1,1,2,NaN,2,NaN,1,NaN,NaN,NaN,NaN;NaN,1,2,NaN,2,1,1,NaN,2,NaN,1,NaN,NaN,NaN,NaN,NaN;NaN,1,NaN,2,NaN,1,1,2,NaN,2,1,2,NaN,NaN,NaN,NaN;NaN,NaN,1,1,2,NaN,2,NaN,1,1,1,1,2,NaN,NaN,NaN;NaN,NaN,NaN,NaN,1,1,1,1,NaN,2,1,1,1,2,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,2,1,1,1,2,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,2,1,1,1,2;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,2,1,1,1;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,2,1,2;];
            set(hDataGui.fig,'Pointer','custom','PointerShapeCData',CData,'PointerShapeHotSpot',[6 6]);
            hDataGui.CursorDownPos(:)=0;        
            if ~isempty(hDataGui.SelectRegion.plot)
                delete(hDataGui.SelectRegion.plot);    
                hDataGui.SelectRegion.plot=[];
            end
        otherwise
            hDataGui.CursorMode='Normal';
            set(hDataGui.fig,'pointer','arrow');
    end
    setappdata(0,'hDataGui',hDataGui);
end

function KeyRelease(~, evnt) 
hDataGui=getappdata(0,'hDataGui');
set(0,'CurrentFigure',hDataGui.fig);
cp=get(hDataGui.aPlot,'currentpoint');
cp=cp(1,[1 2]);
if strcmp(hDataGui.CursorMode,'Zoom');
    if strcmp(evnt.Key,'shift')
        if all(hDataGui.CursorDownPos~=0) && all(hDataGui.CursorDownPos~=cp) 
            xy{1} =  [min(hDataGui.ZoomRegion.X) max(hDataGui.ZoomRegion.X)];
            xy{2} =  [min(hDataGui.ZoomRegion.Y) max(hDataGui.ZoomRegion.Y)];
            set(hDataGui.aPlot,{'xlim','ylim'},xy);
            hDataGui.Zoom.currentXY = xy;
            x_total=hDataGui.Zoom.globalXY{1}(2)-hDataGui.Zoom.globalXY{1}(1);
            y_total=hDataGui.Zoom.globalXY{2}(2)-hDataGui.Zoom.globalXY{2}(1);    
            x_current=hDataGui.Zoom.currentXY{1}(2)-hDataGui.Zoom.currentXY{1}(1);
            y_current=hDataGui.Zoom.currentXY{2}(2)-hDataGui.Zoom.currentXY{2}(1);   
            hDataGui.Zoom.level = -log((x_current/x_total +  y_current/y_total)/2)*8;
        end
        if ~isempty(hDataGui.ZoomRegion.plot)
            delete(hDataGui.ZoomRegion.plot);    
            hDataGui.ZoomRegion.plot=[];
        end
        hDataGui.CursorDownPos(:)=0;     
        hDataGui.CursorMode='Normal';
        setappdata(0,'hDataGui',hDataGui);
        set(hDataGui.fig,'pointer','arrow');
    end
end
 setappdata(0,'hDataGui',hDataGui);
 
function ButtonDown(hObject, eventdata) %#ok<INUSD>
hDataGui=getappdata(0,'hDataGui');
set(0,'CurrentFigure',hDataGui.fig);
set(hDataGui.fig,'CurrentAxes',hDataGui.aPlot);  
cp=get(hDataGui.aPlot,'currentpoint');
cp=cp(1,[1 2]);
pos = get(hDataGui.pPlotPanel,'Position');
cpFig = get(hDataGui.fig,'currentpoint');
cpFig = cpFig(1,[1 2]);
if all(cpFig>=[pos(1) pos(2)]) && all(cpFig<=[pos(1)+pos(3) pos(2)+pos(4)]) 
    if strcmp(get(hDataGui.fig,'SelectionType'),'normal')
        hDataGui.CursorMode='Normal';
        if all(hDataGui.CursorDownPos==0)
            hDataGui.SelectRegion.X=cp(1);
            hDataGui.SelectRegion.Y=cp(2);
            hDataGui.SelectRegion.plot=line(cp(1),cp(2),'Color','black','LineStyle',':','Tag','pSelectRegion');                   
            hDataGui.CursorDownPos=cp;                   
        end
    elseif strcmp(get(hDataGui.fig,'SelectionType'),'extend')
        if strcmp(hDataGui.CursorMode,'Normal');
            hDataGui.CursorMode='Pan';
            hDataGui.CursorDownPos=cp;  
            CData=[NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,1,1,NaN,1,1,NaN,1,1,NaN,NaN,NaN,NaN;NaN,NaN,NaN,1,2,2,1,2,2,1,2,2,1,1,NaN,NaN;NaN,NaN,NaN,1,2,2,2,2,2,2,2,2,1,2,1,NaN;NaN,NaN,NaN,NaN,1,2,2,2,2,2,2,2,2,2,1,NaN;NaN,NaN,NaN,1,1,2,2,2,2,2,2,2,2,2,1,NaN;NaN,NaN,1,2,2,2,2,2,2,2,2,2,2,2,1,NaN;NaN,NaN,1,2,2,2,2,2,2,2,2,2,2,2,1,NaN;NaN,NaN,1,2,2,2,2,2,2,2,2,2,2,1,NaN,NaN;NaN,NaN,NaN,1,2,2,2,2,2,2,2,2,2,1,NaN,NaN;NaN,NaN,NaN,NaN,1,2,2,2,2,2,2,2,1,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,1,2,2,2,2,2,2,1,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,1,2,2,2,2,2,2,1,NaN,NaN,NaN;];
            set(hDataGui.fig,'Pointer','custom','PointerShapeCData',CData,'PointerShapeHotSpot',[10 9]);
        elseif strcmp(hDataGui.CursorMode,'Zoom');
            if all(hDataGui.CursorDownPos==0)
                hDataGui.ZoomRegion.X=cp(1);
                hDataGui.ZoomRegion.Y=cp(2);
                hDataGui.ZoomRegion.plot=line(cp(1),cp(2),'Color','black','LineStyle','--','Tag','pZoomRegion');                   
                hDataGui.CursorDownPos=cp;                   
            end
        end
    end
end
setappdata(0,'hDataGui',hDataGui);

function ButtonUp(hObject, eventdata) %#ok<INUSD>
hDataGui=getappdata(0,'hDataGui');
set(0,'CurrentFigure',hDataGui.fig);
set(hDataGui.fig,'CurrentAxes',hDataGui.aPlot);  
Check=getappdata(hDataGui.fig,'Check');
xy=get(hDataGui.aPlot,{'xlim','ylim'});
cp=get(hDataGui.aPlot,'currentpoint');
cp=cp(1,[1 2]);
X=get(hDataGui.DataPlot,'XData');
Y=get(hDataGui.DataPlot,'YData');
if strcmp(hDataGui.CursorMode,'Normal')    
    k = [];
    if all(hDataGui.CursorDownPos==cp)
        dx=((xy{1}(2)-xy{1}(1))/40);
        dy=((xy{2}(2)-xy{2}(1))/40);
        k=find( abs(X-cp(1))<dx & abs(Y-cp(2))<dy);
        [~,t]=min((X(k)-cp(1)).^2+(Y(k)-cp(2)).^2);
        Check(k(t)) = ~Check(k(t));
    elseif all(hDataGui.CursorDownPos~=0)
        hDataGui.SelectRegion.X=[hDataGui.SelectRegion.X hDataGui.SelectRegion.X(1)];
        hDataGui.SelectRegion.Y=[hDataGui.SelectRegion.Y hDataGui.SelectRegion.Y(1)];
        IN = inpolygon(X,Y,hDataGui.SelectRegion.X,hDataGui.SelectRegion.Y);
        Check(IN) = ~Check(IN);
        k=find(IN==1);
    end
    hDataGui.CursorDownPos(:)=0;        
    if ~isempty(hDataGui.SelectRegion.plot)
        delete(hDataGui.SelectRegion.plot);    
        hDataGui.SelectRegion.plot=[];
    end
    if ~isempty(k)
        data = get(hDataGui.tTable,'Data');
        data(:,1) = num2cell(Check);
        set(hDataGui.tTable,'Data',data);
    end
elseif strcmp(hDataGui.CursorMode,'Pan')    
    hDataGui.CursorDownPos(:)=0;    
    hDataGui.CursorMode='Normal';
    set(hDataGui.fig,'pointer','arrow');
elseif strcmp(hDataGui.CursorMode,'Zoom')  
    if all(hDataGui.CursorDownPos~=0) && all(hDataGui.CursorDownPos~=cp) 
        xy{1} =  [min(hDataGui.ZoomRegion.X) max(hDataGui.ZoomRegion.X)];
        xy{2} =  [min(hDataGui.ZoomRegion.Y) max(hDataGui.ZoomRegion.Y)];
        set(hDataGui.aPlot,{'xlim','ylim'},xy);
        hDataGui.Zoom.currentXY = xy;
        x_total=hDataGui.Zoom.globalXY{1}(2)-hDataGui.Zoom.globalXY{1}(1);
        y_total=hDataGui.Zoom.globalXY{2}(2)-hDataGui.Zoom.globalXY{2}(1);    
        x_current=hDataGui.Zoom.currentXY{1}(2)-hDataGui.Zoom.currentXY{1}(1);
        y_current=hDataGui.Zoom.currentXY{2}(2)-hDataGui.Zoom.currentXY{2}(1);   
        hDataGui.Zoom.level = -log((x_current/x_total +  y_current/y_total)/2)*8;
    else
        if strcmp(get(hDataGui.fig,'SelectionType'),'extend') || strcmp(get(hDataGui.fig,'SelectionType'),'open')
            hDataGui.Zoom.level = hDataGui.Zoom.level + 1;
        else
            hDataGui.Zoom.level = hDataGui.Zoom.level - 1 ;
        end
        setappdata(0,'hDataGui',hDataGui);
        Scroll([],[]);
        hDataGui = getappdata(0,'hDataGui');
    end
    if ~isempty(hDataGui.ZoomRegion.plot)
        delete(hDataGui.ZoomRegion.plot);    
        hDataGui.ZoomRegion.plot=[];
    end
    hDataGui.CursorDownPos(:)=0;    
end
setappdata(hDataGui.fig,'Check',Check);
setappdata(0,'hDataGui',hDataGui);
Draw(hDataGui,-1);


function UpdateCursor(hObject, eventdata) %#ok<INUSD>
hDataGui=getappdata(0,'hDataGui');
set(0,'CurrentFigure',hDataGui.fig);
set(hDataGui.fig,'CurrentAxes',hDataGui.aPlot);  
Object=getappdata(hDataGui.fig,'Object');
pos = get(hDataGui.pPlotPanel,'Position');
cpFig = get(hDataGui.fig,'currentpoint');
cpFig = cpFig(1,[1 2]);
xy=get(hDataGui.aPlot,{'xlim','ylim'});
cp=get(hDataGui.aPlot,'currentpoint');
cp=cp(1,[1 2]);
X=get(hDataGui.DataPlot,'XData');
Y=get(hDataGui.DataPlot,'YData');
if all(cpFig>=[pos(1) pos(2)]) && all(cpFig<=[pos(1)+pos(3) pos(2)+pos(4)])
    if strcmp(hDataGui.CursorMode,'Normal')
        dx=((xy{1}(2)-xy{1}(1))/40);
        dy=((xy{2}(2)-xy{2}(1))/40);
        k=find( abs(X-cp(1))<dx & abs(Y-cp(2))<dy);
        [~,t]=min((X(k)-cp(1)).^2+(Y(k)-cp(2)).^2);
        set(hDataGui.tFrameValue,'String',num2str(Object.Results(k(t),1)));
        if all(hDataGui.CursorDownPos~=0)
            hDataGui.SelectRegion.X=[hDataGui.SelectRegion.X cp(1)];
            hDataGui.SelectRegion.Y=[hDataGui.SelectRegion.Y cp(2)];
            if ~isempty(hDataGui.SelectRegion.plot)
                delete(hDataGui.SelectRegion.plot);    
                hDataGui.SelectRegion.plot=[];
            end
            hDataGui.SelectRegion.plot = line([hDataGui.SelectRegion.X hDataGui.SelectRegion.X(1)] ,[hDataGui.SelectRegion.Y hDataGui.SelectRegion.Y(1)],'Color','black','LineStyle',':','Tag','pSelectRegion');
        end
        set(hDataGui.fig,'pointer','arrow');
    elseif strcmp(hDataGui.CursorMode,'Pan')
        if all(hDataGui.CursorDownPos~=0)
            Zoom=hDataGui.Zoom;
            xy=Zoom.currentXY;
            xy{1}=xy{1}-(cp(1)-hDataGui.CursorDownPos(1));
            xy{2}=xy{2}-(cp(2)-hDataGui.CursorDownPos(2));
            if xy{1}(1)<Zoom.globalXY{1}(1)
                xy{1}=xy{1}-xy{1}(1)+Zoom.globalXY{1}(1);
            end
            if xy{1}(2)>Zoom.globalXY{1}(2)
                xy{1}=xy{1}-xy{1}(2)+Zoom.globalXY{1}(2);
            end
            if xy{2}(1)<Zoom.globalXY{2}(1)
                xy{2}=xy{2}-xy{2}(1)+Zoom.globalXY{2}(1);
            end
            if xy{2}(2)>Zoom.globalXY{2}(2)
                xy{2}=xy{2}-xy{2}(2)+Zoom.globalXY{2}(2);
            end
            set(hDataGui.aPlot,{'xlim','ylim'},xy);
            hDataGui.Zoom.currentXY=xy;
        end
        CData=[NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,1,1,NaN,1,1,NaN,1,1,NaN,NaN,NaN,NaN;NaN,NaN,NaN,1,2,2,1,2,2,1,2,2,1,1,NaN,NaN;NaN,NaN,NaN,1,2,2,2,2,2,2,2,2,1,2,1,NaN;NaN,NaN,NaN,NaN,1,2,2,2,2,2,2,2,2,2,1,NaN;NaN,NaN,NaN,1,1,2,2,2,2,2,2,2,2,2,1,NaN;NaN,NaN,1,2,2,2,2,2,2,2,2,2,2,2,1,NaN;NaN,NaN,1,2,2,2,2,2,2,2,2,2,2,2,1,NaN;NaN,NaN,1,2,2,2,2,2,2,2,2,2,2,1,NaN,NaN;NaN,NaN,NaN,1,2,2,2,2,2,2,2,2,2,1,NaN,NaN;NaN,NaN,NaN,NaN,1,2,2,2,2,2,2,2,1,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,1,2,2,2,2,2,2,1,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,1,2,2,2,2,2,2,1,NaN,NaN,NaN;];
        set(hDataGui.fig,'Pointer','custom','PointerShapeCData',CData,'PointerShapeHotSpot',[10 9]);    
    elseif strcmp(hDataGui.CursorMode,'Zoom')
        if all(hDataGui.CursorDownPos~=0)
            hDataGui.ZoomRegion.X=[hDataGui.ZoomRegion.X(1) hDataGui.ZoomRegion.X(1) cp(1) cp(1) hDataGui.ZoomRegion.X(1)];
            hDataGui.ZoomRegion.Y=[hDataGui.ZoomRegion.Y(1) cp(2) cp(2) hDataGui.ZoomRegion.Y(1) hDataGui.ZoomRegion.Y(1)];
            if ~isempty(hDataGui.ZoomRegion.plot)
                delete(hDataGui.ZoomRegion.plot);    
                hDataGui.ZoomRegion.plot=[];
            end
            hDataGui.ZoomRegion.plot = line(hDataGui.ZoomRegion.X ,hDataGui.ZoomRegion.Y,'Color','black','LineStyle','--','Tag','pZoomRegion');
        end
        CData = [NaN,NaN,NaN,NaN,1,1,1,1,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,1,1,NaN,2,NaN,2,1,1,NaN,NaN,NaN,NaN,NaN,NaN;NaN,1,2,NaN,2,1,1,NaN,2,NaN,1,NaN,NaN,NaN,NaN,NaN;NaN,1,NaN,2,NaN,1,1,2,NaN,2,1,NaN,NaN,NaN,NaN,NaN;1,NaN,2,NaN,2,1,1,NaN,2,NaN,2,1,NaN,NaN,NaN,NaN;1,2,1,1,1,1,1,1,1,1,NaN,1,NaN,NaN,NaN,NaN;1,NaN,1,1,1,1,1,1,1,1,2,1,NaN,NaN,NaN,NaN;1,2,NaN,2,NaN,1,1,2,NaN,2,NaN,1,NaN,NaN,NaN,NaN;NaN,1,2,NaN,2,1,1,NaN,2,NaN,1,NaN,NaN,NaN,NaN,NaN;NaN,1,NaN,2,NaN,1,1,2,NaN,2,1,2,NaN,NaN,NaN,NaN;NaN,NaN,1,1,2,NaN,2,NaN,1,1,1,1,2,NaN,NaN,NaN;NaN,NaN,NaN,NaN,1,1,1,1,NaN,2,1,1,1,2,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,2,1,1,1,2,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,2,1,1,1,2;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,2,1,1,1;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,2,1,2;];
        set(hDataGui.fig,'Pointer','custom','PointerShapeCData',CData,'PointerShapeHotSpot',[6 6]);
    end
    setappdata(0,'hDataGui',hDataGui);
else 
    set(hDataGui.tFrameValue,'String','');
    set(hDataGui.fig,'pointer','arrow');
end

function Close(hObject,eventdata) %#ok<INUSD>
hDataGui=getappdata(0,'hDataGui');
hDataGui.idx=0;
setappdata(0,'hDataGui',hDataGui);
set(hDataGui.fig,'Visible','off','WindowStyle','normal');
fShared('ReturnFocus');
fShow('Tracks');

function Delete(hDataGui)
global Filament;
global Molecule;
hMainGui=getappdata(0,'hMainGui');
Object = getappdata(hDataGui.fig,'Object');
Check = getappdata(hDataGui.fig,'Check');
if sum(Check)<size(Object.Results,1)
    Object.Results(Check==1,:)=[];
    Object.Results(:,5)=sqrt((Object.Results(:,3)-Object.Results(1,3)).^2+(Object.Results(:,4)-Object.Results(1,4)).^2);
    if strcmp(hDataGui.Type,'Filament')==1
        Object.PosStart(Check==1,:)=[];
        Object.PosCenter(Check==1,:)=[];   
        Object.PosEnd(Check==1,:)=[];
        Object.Data(Check==1)=[];        
    end
    if ~isempty(Object.PathData)
        Object.PathData(Check==1,:)=[];   
    end
    Check( Check==1 ) = [];
    CreateTable(hDataGui,[num2cell(Check) num2cell(Object.Results(:,1:8))]);
    setappdata(hDataGui.fig,'Object',Object);
    if strcmp(hDataGui.Type,'Molecule')==1
        Molecule(hDataGui.idx)=Object;
    else
        Filament(hDataGui.idx)=Object;
    end
    [lXaxis,lYaxis]=CreatePlotList(Object,hDataGui.Type);
    set(hDataGui.lXaxis,'UserData',lXaxis);    
    set(hDataGui.lYaxis,'UserData',lYaxis);    
    set(hDataGui.lYaxis2,'UserData',lYaxis);        
    setappdata(hDataGui.fig,'Check',Check);
    Draw(hDataGui,0);
    fRightPanel('UpdateKymoTracks',hMainGui);
end


function Switch(hDataGui)
global Filament;
if strcmp(hDataGui.Type,'Filament')==1
    Object=getappdata(hDataGui.fig,'Object');
    Check = getappdata(hDataGui.fig,'Check');
    PosStart=Object.PosStart;
    PosEnd=Object.PosEnd;
    Orientation=Object.Results(:,8);
    k = find(Check==1)';
    for n = k
        Object.Data{n}=flipud(Object.Data{n});
        Orientation(n)=mod(Orientation(n)+pi,2*pi);
        PosStart(n,:)=Object.PosEnd(n,:);
        PosEnd(n,:)=Object.PosStart(n,:);    
    end
    if all(Object.PosStart==Object.Results(:,3:4))
        Object.Results(:,3:4)=PosStart;
    elseif all(Object.PosEnd==Object.Results(:,3:4))
        Object.Results(:,3:4)=PosEnd;
    end
    Object.PosStart=PosStart;
    Object.PosEnd=PosEnd;    
    Object.Results(:,8)=Orientation;   
    Object.Results(:,5)=sqrt((Object.Results(:,3)-Object.Results(1,3)).^2+(Object.Results(:,4)-Object.Results(1,4)).^2);
    Filament(hDataGui.idx)=Object;
    [lXaxis,lYaxis]=CreatePlotList(Object,hDataGui.Type);
    set(hDataGui.lXaxis,'UserData',lXaxis);    
    set(hDataGui.lYaxis,'UserData',lYaxis);    
    set(hDataGui.lYaxis2,'UserData',lYaxis);        
    Check(:)=0;
    CreateTable(hDataGui,[num2cell(Check) num2cell(Object.Results(:,1:8))]);
    setappdata(hDataGui.fig,'Check',Check);
    setappdata(hDataGui.fig,'Object',Object);
    Draw(hDataGui,0);
end
ReturnFocus([],[]);

function Split(hDataGui)
global Filament;
global Molecule;
hMainGui=getappdata(0,'hMainGui');
Object=getappdata(hDataGui.fig,'Object');
Check = getappdata(hDataGui.fig,'Check');
if sum(Check)<length(Check)
    Object.Results(Check==0,:)=[];
    Object.Results(:,5)=sqrt((Object.Results(:,3)-Object.Results(1,3)).^2+(Object.Results(:,4)-Object.Results(1,4)).^2);
    if strcmp(hDataGui.Type,'Filament')==1
        Object.PosCenter(Check==0,:)=[];   
        Object.PosStart(Check==0,:)=[];
        Object.PosEnd(Check==0,:)=[];
        Object.Data(Check==0)=[];
    end
    if ~isempty(Object.PathData)
        Object.PathData(Check==0,:)=[];      
    end
    Object.Name=sprintf('New %s',Object.Name);
    if strcmp(hDataGui.Type,'Molecule')
        Molecule(length(Molecule)+1)=Object;
        fRightPanel('UpdateList',hMainGui.RightPanel.pData.MolList,Molecule,hMainGui.RightPanel.pData.sMolList,hMainGui.Menu.ctListMol);
    elseif strcmp(hDataGui.Type,'Filament')
        Filament(length(Filament)+1)=Object;
        fRightPanel('UpdateList',hMainGui.RightPanel.pData.FilList,Filament,hMainGui.RightPanel.pData.sFilList,hMainGui.Menu.ctListFil);    
    end
    Delete(hDataGui);
end
ReturnFocus([],[]);

function Drift(hDataGui)
global Molecule;
global Filament;
Object=getappdata(hDataGui.fig,'Object');
hMainGui=getappdata(0,'hMainGui');
Drift=getappdata(hMainGui.fig,'Drift');
Check = getappdata(hDataGui.fig,'Check');
if ~isempty(Drift)
    if get(hDataGui.cDrift,'Value')==1
        t=-1;
    else
        t=1;
    end
    nData=size(Object.Results,1);
    for i=1:nData
        k=find(Drift(:,1)==Object.Results(i,1));
        if length(k)==1
            Object.Results(i,3:4)=Object.Results(i,3:4)+t*Drift(k,2:3);
            if (size(Object.Results,2)==10)&&size(Drift,2)==5
                Object.Results(i,8) = Object.Results(i,8) - t* norm(Drift(k,4:5));
            end
            if isfield(Object,'PosCenter')
                Object.PosStart(i,:) = Object.PosStart(i,:) + t*Drift(k,2:3);
                Object.PosCenter(i,:) = Object.PosCenter(i,:) + t*Drift(k,2:3);
                Object.PosEnd(i,:) = Object.PosEnd(i,:) + t*Drift(k,2:3);
                Object.Data{i}(:,1) = Object.Data{i}(:,1) + t*Drift(k,2);
                Object.Data{i}(:,2) = Object.Data{i}(:,2) + t*Drift(k,3);            
            end
        end
       Object.Results(i,5)=norm([Object.Results(i,3)-Object.Results(1,3) Object.Results(i,4)-Object.Results(1,4)]);
    end
    Object.Drift=get(hDataGui.cDrift,'Value');
    if strcmp(hDataGui.Type,'Molecule')==1
        Molecule(hDataGui.idx)=Object;
    else
        Filament(hDataGui.idx)=Object;
    end
    CreateTable(hDataGui,[num2cell(Check) num2cell(Object.Results(:,1:8))]);
    setappdata(hDataGui.fig,'Object',Object);
    [lXaxis,lYaxis]=CreatePlotList(Object,hDataGui.Type);
    set(hDataGui.lXaxis,'String',lXaxis.list,'UserData',lXaxis);    
    set(hDataGui.lYaxis,'UserData',lYaxis);    
    set(hDataGui.lYaxis2,'UserData',lYaxis); 
    x=get(hDataGui.lXaxis,'Value');
    if x==length(lXaxis.list)
        CreateHistograms(hDataGui);
    end
    Draw(hDataGui,0);
end
ReturnFocus([],[]);

function Select(~, ~)
hDataGui=getappdata(0,'hDataGui');
data = get(hDataGui.tTable,'Data');
Check = cell2mat(data(:,1));
setappdata(hDataGui.fig,'Check',Check);
Draw(hDataGui,-1);
ReturnFocus([],[]);

function SelectAll(hDataGui)
data = get(hDataGui.tTable,'Data');
if get(gcbo,'UserData')==1
    Check = true(size(data,1),1);
else
    Check = false(size(data,1),1);
end
data(:,1) = num2cell(Check);
CreateTable(hDataGui,data);
setappdata(hDataGui.fig,'Check',Check);
Draw(hDataGui,-1);
ReturnFocus([],[]);

function [lXaxis,lYaxis]=CreatePlotList(Object,Type)
vel=CalcVelocity(Object);
%create list for X-Axis
n=4;
lXaxis.list{1}='x-position';
lXaxis.data{1}=Object.Results(:,3);
lXaxis.units{1}='[nm]';
lXaxis.list{2}='time';
lXaxis.data{2}=Object.Results(:,2);
lXaxis.units{2}='[s]';
lXaxis.list{3}='distance(to origin)';
lXaxis.data{3}=Object.Results(:,5);
lXaxis.units{3}='[nm]';
if ~isempty(Object.PathData)
    lXaxis.list{n}='distance(along path)';
    lXaxis.data{n}=Object.PathData(:,3);
    lXaxis.units{n}='[nm]';
    n=n+1;
end
lXaxis.list{n}='histogram';
lXaxis.data{n}=[];

%create Y-Axis list for xy-plot
lYaxis(1).list{1}='y-position';
lYaxis(1).data{1}=Object.Results(:,4);
lYaxis(1).units{1}='[nm]';

%create Y-Axis list for time plot
n=2;
lYaxis(2).list{1}='distance(to origin)';
lYaxis(2).data{1}=Object.Results(:,5);
lYaxis(2).units{1}='[nm]';
if ~isempty(Object.PathData)
    lYaxis(2).list{n}='distance(along path)';
    lYaxis(2).data{n}=Object.PathData(:,3);
    lYaxis(2).units{n}='[nm]';
    lYaxis(2).list{n+1}='sideways(to path)';
    lYaxis(2).data{n+1}=Object.PathData(:,4);
    lYaxis(2).units{n+1}='[nm]';
    n=n+2;
end

lYaxis(2).list{n}='velocity';
lYaxis(2).data{n}=vel;
lYaxis(2).units{n}='[nm/s]';
n=n+1;

if strcmp(Type,'Molecule')==1
    if strcmp(Object.Type,'symmetric')
        lYaxis(2).list{n}='width(FWHM)';
    else
        lYaxis(2).list{n}='average width(FWHM)';
    end
    lYaxis(2).data{n}=Object.Results(:,6);
    lYaxis(2).units{n}='[nm]';    
    lYaxis(2).list{n+1}='amplitude';
    lYaxis(2).data{n+1}=Object.Results(:,7);
    lYaxis(2).units{n+1}='[ABU]';    
    n=n+2;
    if strcmp(Object.Type,'symmetric')
        lYaxis(2).list{n}='intensity(volume)';
        lYaxis(2).data{n}=2*pi*(Object.Results(:,6)/Object.PixelSize/(2*sqrt(2*log(2)))).^2.*Object.Results(:,7);       
        lYaxis(2).units{n}='[ABU]';        
        n=n+1;
    end
else
    lYaxis(2).list{n}='length';
    lYaxis(2).data{n}=Object.Results(:,6);       
    lYaxis(2).units{n}='[nm]';       
    lYaxis(2).list{n+1}='average amplitude';
    lYaxis(2).data{n+1}=Object.Results(:,7);
    lYaxis(2).units{n+1}='[ABU]';        
    lYaxis(2).list{n+2}='orientation(angle to x-axis)';
    lYaxis(2).data{n+2}=Object.Results(:,8);
    lYaxis(2).units{n+2}='[rad]';        
    n=n+3;
end

lYaxis(2).list{n}='x-position';
lYaxis(2).data{n}=Object.Results(:,3);
lYaxis(2).units{n}='[nm]';
lYaxis(2).list{n+1}='y-position';
lYaxis(2).data{n+1}=Object.Results(:,4);   
lYaxis(2).units{n+1}='[nm]';
n=n+2;
if strcmp(Type,'Molecule')==1
    lYaxis(2).list{n}='fit error of center';
    lYaxis(2).data{n}=Object.Results(:,8);        
    lYaxis(2).units{n}='[nm]'; 
    n=n+1;
    if strcmp(Object.Type,'streched')
        lYaxis(2).list{n}='width of major axis(FWHM)';
        lYaxis(2).data{n}=Object.Results(:,9);   
        lYaxis(2).units{n}='[nm]';        
        lYaxis(2).list{n+1}='width of minor axis(FWHM)';
        lYaxis(2).data{n+1}=Object.Results(:,10);      
        lYaxis(2).units{n+1}='[nm]';              
        lYaxis(2).list{n+2}='orientation(angle to x-axis)';    
        lYaxis(2).data{n+2}=Object.Results(:,11);      
        lYaxis(2).units{n+2}='[rad]';              
    elseif strcmp(Object.Type,'ring1')
        lYaxis(2).list{n}='Radius ring';
        lYaxis(2).data{n}=Object.Results(:,9);      
        lYaxis(2).units{n}='[nm]';                    
        lYaxis(2).list{n+1}='Amplitude ring';
        lYaxis(2).data{n+1}=Object.Results(:,10);                
        lYaxis(2).units{n+1}='[ABU]';                    
        lYaxis(2).list{n+2}='Width (FWHM) ring';   
        lYaxis(2).data{n+2}=Object.Results(:,11);                
        lYaxis(2).units{n+2}='[nm]';        
    elseif strcmp(Object.Type,'ring2')
        lYaxis(2).list{n}='Radius inner ring';
        lYaxis(2).data{n}=Object.Results(:,9);   
        lYaxis(2).units{n}='[nm]';        
        lYaxis(2).list{n+1}='Amplitude inner ring';
        lYaxis(2).data{n+1}=Object.Results(:,10);      
        lYaxis(2).units{n+1}='[ABU]';              
        lYaxis(2).list{n+2}='Width (FWHM) inner ring';    
        lYaxis(2).data{n+2}=Object.Results(:,11);      
        lYaxis(2).units{n+2}='[nm]';              
        lYaxis(2).list{n+3}='Radius outer ring';
        lYaxis(2).data{n+3}=Object.Results(:,12);      
        lYaxis(2).units{n+3}='[nm]';              
        lYaxis(2).list{n+4}='Amplitude outer ring';
        lYaxis(2).data{n+4}=Object.Results(:,13);      
        lYaxis(2).units{n+4}='[ABU]';                      
        lYaxis(2).list{n+5}='Width (FWHM) outer ring';        
        lYaxis(2).data{n+5}=Object.Results(:,14);     
        lYaxis(2).units{n+5}='[nm]';      
    end
end

%create Y-Axis list for distance plot
lYaxis(3)=lYaxis(2);
lYaxis(3).list(1)=[];
lYaxis(3).data(1)=[];
lYaxis(3).units(1)=[];
n=4;
if ~isempty(Object.PathData)
    lYaxis(3).list(1)=[];
    lYaxis(3).data(1)=[];
    lYaxis(3).units(1)=[];
    lYaxis(4)=lYaxis(3);
    n=5;
end

%create list for histograms
lYaxis(n).list{1}='Velocity';
lYaxis(n).units{1}='[nm/s]';
lYaxis(n).data{1}=[];

lYaxis(n).list{2}='Pairwise-Distance';
lYaxis(n).units{2}='[nm]';
lYaxis(n).data{2}=[];
k=3;
if ~isempty(Object.PathData)
    lYaxis(n).list{k}='Pairwise-Distance (Path)';
    lYaxis(n).data{k}=[];
    lYaxis(n).units{k}='[nm]';
    k=k+1;
end

lYaxis(n).list{k}='Amplitude';
lYaxis(n).units{k}='[ABU]';
lYaxis(n).data{k}=[];
if strcmp(Type,'Molecule')==1
    lYaxis(n).list{k+1}='Intensity (Volume)';
    lYaxis(n).units{k+1}='[ABU]';
    lYaxis(n).data{k+1}=[];
else
    lYaxis(n).list{k+1}='Length';
    lYaxis(n).units{k+1}='[nm]';
    lYaxis(n).data{k+1}=[];
end

function CreateHistograms(hDataGui)
Object=getappdata(hDataGui.fig,'Object');
lYaxis=get(hDataGui.lYaxis,'UserData');
vel=CalcVelocity(Object);
n=length(lYaxis);
barchoice=[1 2 4 5 10 20 25 50 100 200 250 500 1000 2000 5000 10000 50000 10^5 10^6 10^7 10^8];

total=(max(vel)-min(vel))/15;
[~,t]=min(abs(total-barchoice));
barwidth=barchoice(t(1));
x=fix(min(vel)/barwidth)*barwidth-barwidth:barwidth:ceil(max(vel)/barwidth)*barwidth+barwidth;
num = hist(vel,x);
lYaxis(n).data{1}=[x' num']; 

XPos=Object.Results(:,3);
YPos=Object.Results(:,4);
pairwise=zeros(length(XPos));
for i=1:length(XPos)
    pairwise(:,i)=sqrt((XPos-XPos(i)).^2 + (YPos-YPos(i)).^2);
end
p=tril(pairwise,-1);
pairwise=p(p>1);
x=round(min(pairwise)-10):1:round(max(pairwise)+10);
num = hist(pairwise,x);
lYaxis(n).data{2}=[x' num']; 
k=3;
if isfield(Object,'PathData')
    if ~isempty(Object.PathData)
        Dis=Object.PathData(:,3);
        pairwise=zeros(length(Dis));
        for i=1:length(Dis)
            pairwise(:,i)=Dis-Dis(i);
        end
        p=tril(pairwise,-1);
        pairwise=p(p>1);
        x=round(min(pairwise)-10):1:round(max(pairwise)+10);
        num = hist(pairwise,x);
        lYaxis(n).data{k}=[x' num']; 
        k=k+1;
    end
end

Amp=Object.Results(:,7);
total=(max(Amp)-min(Amp))/15;
[~,t]=min(abs(total-barchoice));
barwidth=barchoice(t(1));
x=fix(min(Amp)/barwidth)*barwidth-barwidth:barwidth:ceil(max(Amp)/barwidth)*barwidth+barwidth;
num = hist(Amp,x);
lYaxis(n).data{k}=[x' num'];

if strcmp(hDataGui.Type,'Molecule')==1
    Int=2*pi*Object.Results(:,6).^2.*Object.Results(:,7);
    total=(max(Int)-min(Int))/15;
    [~,t]=min(abs(total-barchoice));
    barwidth=barchoice(t(1));
    x=fix(min(Int)/barwidth)*barwidth-barwidth:barwidth:ceil(max(Int)/barwidth)*barwidth+barwidth;
    num = hist(Int,x);
    lYaxis(n).data{k+1}=[x' num'];
else
    Len=Object.Results(:,6);
    total=(max(Len)-min(Len))/15;
    [~,t]=min(abs(total-barchoice));
    barwidth=barchoice(t(1));
    x=fix(min(Len)/barwidth)*barwidth-barwidth:barwidth:ceil(max(Len)/barwidth)*barwidth+barwidth;
    num = hist(Len,x);
    lYaxis(n).data{k+1}=[x' num'];
end
set(hDataGui.lYaxis,'UserData',lYaxis);


function XAxisList(hDataGui)
x=get(hDataGui.lXaxis,'Value');
y=get(hDataGui.lYaxis,'Value');
y2=get(hDataGui.lYaxis2,'Value');
s=get(hDataGui.lXaxis,'UserData');
a=get(hDataGui.lYaxis,'UserData');
enable='off';
enable2='off';
if x>1 && x<length(s.list)
    enable='on';
    if get(hDataGui.cYaxis2,'Value')==1
        enable2='on';
    end
end
if length(a(x).list)<y
    set(hDataGui.lYaxis,'Value',1);
end
if length(a(x).list)<y2
    set(hDataGui.lYaxis2,'Value',1);
end    
set(hDataGui.lYaxis,'String',a(x).list);
set(hDataGui.lYaxis2,'String',a(x).list);
set(hDataGui.cYaxis2,'Enable',enable);
set(hDataGui.tYaxis2,'Enable',enable2);
set(hDataGui.lYaxis2,'Enable',enable2);
if x==length(s.list) && isempty(a(x).data{1});
    CreateHistograms(hDataGui);
end
Draw(hDataGui,0);

function CheckYAxis2(hDataGui)
c=get(hDataGui.cYaxis2,'Value');
enable='off';
if c==1
    enable='on';
end
set(hDataGui.tYaxis2,'Enable',enable);
set(hDataGui.lYaxis2,'Enable',enable);
Draw(hDataGui,0);

function vel=CalcVelocity(Object)
nData=size(Object.Results,1);
if nData>1
    vel=zeros(nData,1);
    vel(1)=sqrt( (Object.Results(1,3)-(Object.Results(2,3)))^2 +...
                 (Object.Results(1,4)-(Object.Results(2,4)))^2)/...
                 (Object.Results(2,2)-(Object.Results(1,2)));
    vel(nData)=sqrt((Object.Results(nData,3)-(Object.Results(nData-1,3)))^2 +...
                    (Object.Results(nData,4)-(Object.Results(nData-1,4)))^2)/...
                    (Object.Results(nData,2)-(Object.Results(nData-1,2)));
    for i=2:nData-1
       vel(i)=(sqrt( (Object.Results(i,3)-(Object.Results(i-1,3)))^2 +...
                     (Object.Results(i,4)-(Object.Results(i-1,4)))^2)+...
               sqrt( (Object.Results(i+1,3)-(Object.Results(i,3)))^2 +...
                     (Object.Results(i+1,4)-(Object.Results(i,4)))^2))/...                    
                     (Object.Results(i+1,2)-(Object.Results(i-1,2)));
    end
else
    vel=0;
end

function Scroll(hObject,eventdata) %#ok<INUSL>
hDataGui=getappdata(0,'hDataGui');
set(0,'CurrentFigure',hDataGui.fig);
set(hDataGui.fig,'CurrentAxes',hDataGui.aPlot);  
pos = get(hDataGui.pPlotPanel,'Position');
cpFig = get(hDataGui.fig,'currentpoint');
cpFig = cpFig(1,[1 2]);
xy=get(hDataGui.aPlot,{'xlim','ylim'});
cp=get(hDataGui.aPlot,'currentpoint');
cp=cp(1,[1 2]);
if all(cpFig>=[pos(1) pos(2)]) && all(cpFig<=[pos(1)+pos(3) pos(2)+pos(4)])
    Zoom=hDataGui.Zoom;
    if ~isempty(eventdata)
        level=Zoom.level-eventdata.VerticalScrollCount;
    else
        level=Zoom.level;
    end
    if level<1
        Zoom.currentXY=Zoom.globalXY;
        Zoom.level=0;
    else
        x_total=Zoom.globalXY{1}(2)-Zoom.globalXY{1}(1);
        y_total=Zoom.globalXY{2}(2)-Zoom.globalXY{2}(1);    
        x_current=Zoom.currentXY{1}(2)-Zoom.currentXY{1}(1);
        y_current=Zoom.currentXY{2}(2)-Zoom.currentXY{2}(1);        
        p=exp(-level/8);
        cp=cp(1,[1 2]);
        if strcmp(get(hDataGui.aPlot,'YDir'),'reverse');
            if (y_current/x_current) >= Zoom.aspect
                new_scale_y = y_total*p;
                new_scale_x = new_scale_y/Zoom.aspect;
            else
                new_scale_x = x_total*p;
                new_scale_y = new_scale_x*Zoom.aspect;
            end
        else
            new_scale_y = y_total*p;
            new_scale_x = x_total*p;
        end
        xy{1}=[cp(1)-(cp(1)-Zoom.currentXY{1}(1))/x_current*new_scale_x cp(1)+(Zoom.currentXY{1}(2)-cp(1))/x_current*new_scale_x];
        xy{2}=[cp(2)-(cp(2)-Zoom.currentXY{2}(1))/y_current*new_scale_y cp(2)+(Zoom.currentXY{2}(2)-cp(2))/y_current*new_scale_y];
        if xy{1}(1)<Zoom.globalXY{1}(1)
            xy{1}=xy{1}-xy{1}(1)+Zoom.globalXY{1}(1);
        end
        if xy{1}(2)>Zoom.globalXY{1}(2)
            xy{1}=xy{1}-xy{1}(2)+Zoom.globalXY{1}(2);
        end
        if xy{2}(1)<Zoom.globalXY{2}(1)
            xy{2}=xy{2}-xy{2}(1)+Zoom.globalXY{2}(1);
        end
        if xy{2}(2)>Zoom.globalXY{2}(2)
            xy{2}=xy{2}-xy{2}(2)+Zoom.globalXY{2}(2);
        end
        Zoom.currentXY=xy;
        Zoom.level=level;
    end
    set(hDataGui.aPlot,{'xlim','ylim'},Zoom.currentXY);
    hDataGui.Zoom=Zoom;
    setappdata(0,'hDataGui',hDataGui);
end

function ReturnFocus(~,~)
hDataGui=getappdata(0,'hDataGui');
warning off MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame
javaFrame = get(hDataGui.fig,'JavaFrame');
javaFrame.getAxisComponent.requestFocus;