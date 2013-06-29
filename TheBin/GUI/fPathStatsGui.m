function fPathStatsGui(func,varargin)
switch func
    case 'Create'
        Create;
    case 'Update'
        Update(varargin{1});        
    case 'Draw'
        Draw(varargin{1});  
    case 'bToggleToolCursor'
        bToggleToolCursor(varargin{1});  
    case 'bToolPan'
        bToolPan(varargin{1});
    case 'bToolZoomIn'
        bToolZoomIn(varargin{1});
    case 'Drift'
        Drift(varargin{1});  
    case 'Load'
        Load(varargin{1});  
    case 'Cancel'
        Cancel(varargin{1});          
    case 'Ok'
        Ok(varargin{1});                  
end

function Create
global Molecule;
global Filament;
global Index;

h=findobj('Tag','hPathsStatsGui');
close(h)

MolSelect = [Molecule.Selected];
FilSelect = [Filament.Selected];
if all(MolSelect==0) && all(FilSelect==0)
    fMsgDlg('No track selected!','error');
    return;
end
button =  fQuestDlg('How should FIESTA find the path?','Path Statistics',{'Fit','Filament','Average'},'Fit');
if isempty(button)
    return;
end
if strcmp(button,'Average')
    AverageDis = round(str2double(fInputDlg('Average Distance in nm:','')));
end

if strcmp(button,'Filament')
    if all(MolSelect==0)
        fMsgDlg('No molecules selected!','error');
        return;
    end
    if isempty(Filament)
        fMsgDlg('No filaments present!','error');
        return;
    end
    FilSelect(:) = 0;
end
PathMol = Molecule(MolSelect==1);
PathMol = rmfield(PathMol,'Type');
PathFil = Filament(FilSelect==1);
PathFil = rmfield(PathFil,{'Data','PosStart','PosCenter','PosEnd'});
PathStats = [PathMol PathFil];
Index = [ find(MolSelect==1) find(FilSelect==1)*1i ];

hPathsStatsGui.fig = figure('Units','normalized','DockControls','off','IntegerHandle','off','MenuBar','none','Name','Path Statistics',...
                      'NumberTitle','off','HandleVisibility','callback','Tag','hPathsStatsGui',...
                      'Visible','off','Resize','off','WindowStyle','modal');
                  
fPlaceFig(hPathsStatsGui.fig,'big');

if ispc
    set(hPathsStatsGui.fig,'Color',[236 233 216]/255);
end

c=get(hPathsStatsGui.fig,'Color');

hPathsStatsGui.pPlotXYPanel = uipanel('Parent',hPathsStatsGui.fig,'Position',[0.45 0.625 0.525 0.35],'Tag','PlotPanel','BackgroundColor','white');

hPathsStatsGui.tCalcPath = uicontrol('Parent',hPathsStatsGui.pPlotXYPanel,'Units','normalized','Position',[00 0.3 1 0.4],'FontSize',12,'FontWeight','bold',...
                        'String','Calculating Path','Style','text','Tag','tCalcPath','HorizontalAlignment','center','BackgroundColor','white');
                    
hPathsStatsGui.aPlotXY = axes('Parent',hPathsStatsGui.pPlotXYPanel,'Units','normalized','OuterPosition',[0 0 1 1],'Tag','aPlotXY','Visible','off');
                    
hPathsStatsGui.lAll = uicontrol('Parent',hPathsStatsGui.fig,'Units','normalized','BackgroundColor',[1 1 1],'Callback','fPathStatsGui(''Update'',getappdata(0,''hPathsStatsGui''));',...
                           'Position',[0.025 0.83 0.375 0.15],'String',{PathStats.Name},'Style','listbox','Value',1,'Tag','lAll','Max',length(PathStats));                         
                       
hPathsStatsGui.pOptions = uipanel('Parent',hPathsStatsGui.fig,'Units','normalized','Title','Options',...
                             'Position',[0.025 0.625 0.375 0.19],'Tag','pOptions','BackgroundColor',c);

if ~isempty(PathStats)
    hPathsStatsGui.cDrift = uicontrol('Parent',hPathsStatsGui.pOptions,'Units','normalized','Callback','fPathStatsGui(''Drift'',getappdata(0,''hPathsStatsGui''));',...
                            'Position',[0.1 0.86 0.6 0.12],'String','Correct for Drift','Style','radiobutton','BackgroundColor',c,'Tag','cDrift','Value',PathStats(1).Drift);     
else
    hPathsStatsGui.cDrift = uicontrol('Parent',hPathsStatsGui.pOptions,'Units','normalized','Callback','fPathStatsGui(''Drift'',getappdata(0,''hPathsStatsGui''));',...
                            'Position',[0.1 0.86 0.6 0.12],'String','Correct for Drift','Style','radiobutton','BackgroundColor',c,'Tag','cDrift','Value',0);     
end

                        
hPathsStatsGui.bAuto = uicontrol('Parent',hPathsStatsGui.pOptions,'Units','normalized','Callback','fPathStatsGui(''Update'',getappdata(0,''hPathsStatsGui''));',...
                            'Position',[0.75 0.675 0.225 0.3],'String','Auto Fit','Tag','bReset');    
                        
hPathsStatsGui.bReset = uicontrol('Parent',hPathsStatsGui.pOptions,'Units','normalized','Callback','fPathStatsGui(''Update'',getappdata(0,''hPathsStatsGui''));',...
                            'Position',[0.75 0.35 0.225 0.3],'String','Reset plots','Tag','bReset');                        
                        
hPathsStatsGui.bDisregard = uicontrol('Parent',hPathsStatsGui.pOptions,'Units','normalized','Callback','fPathStatsGui(''Update'',getappdata(0,''hPathsStatsGui''));',...
                            'Position',[0.75 0.025 0.225 0.3],'String','Disregard','Tag','bReset');                            
                        
hPathsStatsGui.rLinear = uicontrol('Parent',hPathsStatsGui.pOptions,'Units','normalized','Callback','fPathStatsGui(''Update'',getappdata(0,''hPathsStatsGui''));',...
                            'Position',[0.1 0.72 0.6 0.12],'String','Linear path','Style','radiobutton','BackgroundColor',c,'Tag','rLinear','Value',0);                         

hPathsStatsGui.rPoly2 = uicontrol('Parent',hPathsStatsGui.pOptions,'Units','normalized','Callback','fPathStatsGui(''Update'',getappdata(0,''hPathsStatsGui''));',...
                            'Position',[0.1 0.60 0.6 0.12],'String','2nd deg polynomial path','Style','radiobutton','BackgroundColor',c,'Tag','rPoly2','Value',0);          

hPathsStatsGui.rPoly3 = uicontrol('Parent',hPathsStatsGui.pOptions,'Units','normalized','Callback','fPathStatsGui(''Update'',getappdata(0,''hPathsStatsGui''));',...
                            'Position',[0.1 0.48 0.6 0.12],'String','3rd deg polynomial path','Style','radiobutton','BackgroundColor',c,'Tag','rPoly3','Value',0);                          

hPathsStatsGui.rFilament = uicontrol('Parent',hPathsStatsGui.pOptions,'Units','normalized','Callback','fPathStatsGui(''Update'',getappdata(0,''hPathsStatsGui''));',...
                                    'Position',[0.1 0.34 0.6 0.12],'String','Filament path','Style','radiobutton','BackgroundColor',c,'Tag','rFilament','Value',0);                          

if isempty(Filament)
    set(hPathsStatsGui.rFilament,'Enable','off');
end

hPathsStatsGui.rAverage = uicontrol('Parent',hPathsStatsGui.pOptions,'Units','normalized','Callback','fPathStatsGui(''Update'',getappdata(0,''hPathsStatsGui''));',...
                            'Position',[0.1 0.18 0.6 0.12],'String','Average path','Style','radiobutton','BackgroundColor',c,'Tag','rAverage','Value',0);   

hPathsStatsGui.tRegion = uicontrol('Parent',hPathsStatsGui.pOptions,'Units','normalized','Enable','off','HorizontalAlignment','left',...
                              'Position',[0.15 0.02 0.15 0.12],'String','Region:','Style','text','Tag','tRegion','BackgroundColor',c);                         

hPathsStatsGui.eAverage = uicontrol('Parent',hPathsStatsGui.pOptions,'Units','normalized','Callback','fPathStatsGui(''Update'',getappdata(0,''hPathsStatsGui''));','Enable','off',...
                              'Position',[0.3 0.02 0.3 0.16],'String','1000','FontSize',8,'Style','edit','Tag','eAverage','BackgroundColor',[1 1 1]);                         
                          
hPathsStatsGui.tNM = uicontrol('Parent',hPathsStatsGui.pOptions,'Units','normalized','Position',[0.62 0.02 0.1 0.12],'Enable','off',...
                               'String','nm','Style','text','Tag','tNM','HorizontalAlignment','left','BackgroundColor',c);

hPathsStatsGui.pPlotDistPanel = uipanel('Parent',hPathsStatsGui.fig,'Position',[0.025 0.28 0.95 0.335],'Tag','PlotPanel','BackgroundColor','white');

hPathsStatsGui.aPlotDist = axes('Parent',hPathsStatsGui.pPlotDistPanel,'Units','normalized','OuterPosition',[0 0 1 1],'Tag','aPlotDist');

hPathsStatsGui.pPlotSidePanel = uipanel('Parent',hPathsStatsGui.fig,'Position',[0.025 0.05 0.95 0.22],'Tag','PlotPanel','BackgroundColor','white');

hPathsStatsGui.aPlotSide = axes('Parent',hPathsStatsGui.pPlotSidePanel ,'Units','normalized','OuterPosition',[0 0 1 1],'Tag','aPlotSide');
    
hPathsStatsGui.bOk = uicontrol('Parent',hPathsStatsGui.fig,'Units','normalized','Callback','fPathStatsGui(''Ok'',getappdata(0,''hPathsStatsGui''));',...
                            'Position',[0.575 0.01 0.175 0.03],'String','Ok','Tag','bOk');

hPathsStatsGui.bCancel = uicontrol('Parent',hPathsStatsGui.fig,'Units','normalized','Callback','fPathStatsGui(''Cancel'',getappdata(0,''hPathsStatsGui''));',...
                             'Position',[0.8 0.01 0.175 0.03],'String','Cancel','Tag','bCancel');                        

set(hPathsStatsGui.fig, 'WindowButtonMotionFcn', @UpdateCursor);
set(hPathsStatsGui.fig, 'WindowButtonUpFcn',@ButtonUp);
set(hPathsStatsGui.fig, 'WindowButtonDownFcn',@ButtonDown);
set(hPathsStatsGui.fig, 'WindowScrollWheelFcn',@Scroll);  

hPathsStatsGui.CursorMode = 'Normal';
hPathsStatsGui.Zoom = struct('currentXY',[],'globalXY',[],'level',[],'aspect',GetAxesAspectRatio(hPathsStatsGui.aPlotXY));

setappdata(0,'hPathsStatsGui',hPathsStatsGui);
setappdata(hPathsStatsGui.fig,'PathStats',PathStats);

if ~isempty(PathStats)
    if strcmp(button,'Filament')
        [XPosFil,YPosFil,FrameFil]=InterpolFil(Filament);
    else
        XPosFil = [];
        YPosFil = [];
        FrameFil = [];
    end    
    setappdata(hPathsStatsGui.fig,'XPosFil',XPosFil);
    setappdata(hPathsStatsGui.fig,'YPosFil',YPosFil);        
    setappdata(hPathsStatsGui.fig,'FrameFil',FrameFil);            
    workbar(0/(length(PathStats)),'Calculating path','Progress',-1);
    nPathStats = length(PathStats);
    n=1;
    while n <= nPathStats
        if isempty(PathStats(n).PathData)
            if size(PathStats(n).Results,1)>3
                if strcmp(button,'Fit')
                    X = double(PathStats(n).Results(:,3));
                    Y = double(PathStats(n).Results(:,4));    
                    [param1,resnorm1] = PathFitLinear(X,Y);
                    [PathX,PathY,Dis,Side] = LinearPath(X,Y,param1);
                    try
                        [param2,resnorm2] = PathFitPoly2(X,Y,Side,param1); 
                    catch
                        resnorm2=Inf;
                    end
                    try
                        [param3,resnorm3] = PathFitPoly3(X,Y,Side,param1); 
                    catch
                        resnorm3=Inf;
                    end
                    if all(resnorm1<[resnorm2 resnorm3])
                        if n == 1
                            set(hPathsStatsGui.rLinear,'Value',1);  
                        end
                        PathStats(n).AverageDis = -1;
                    elseif all(resnorm2<[resnorm1 resnorm3])
                        [PathX,PathY,Dis,Side]=Poly2Path(X,Y,param2);
                        PathStats(n).AverageDis = -2;
                        if n == 1
                            set(hPathsStatsGui.rPoly2,'Value',1);   
                        end
                    elseif all(resnorm3<[resnorm1 resnorm2])
                        [PathX,PathY,Dis,Side]=Poly3Path(X,Y,param3);
                        PathStats(n).AverageDis = -3;
                        if n == 1
                            set(hPathsStatsGui.rPoly3,'Value',1); 
                        end
                    end
                elseif strcmp(button,'Average')
                    [PathX,PathY,Dis,Side] = AveragePath(PathStats(n).Results(:,1:4),AverageDis);
                    PathStats(n).AverageDis = AverageDis;
                    if n == 1
                        set(hPathsStatsGui.rAverage,'Value',1); 
                        set(hPathsStatsGui.eAverage,'Enable','on','String',num2str(PathStats(1).AverageDis)); 
                        set(hPathsStatsGui.tNM,'Enable','on');
                    end
                elseif strcmp(button,'Filament')
                    nFil = size(XPosFil,1);
                    if nFil > 1
                        s = zeros(nFil,1);
                        for m = 1:nFil
                            [~,~,~,Side] = FilamentPath(PathStats(n).Results,XPosFil(m,:),YPosFil(m,:),FrameFil{m},0);
                            s(m) = mean(abs(Side));
                        end
                        [~,k] = min(s);
                    else
                        k = 1;
                    end
                    [PathX,PathY,Dis,Side]=FilamentPath(PathStats(n).Results,XPosFil(k,:),YPosFil(k,:),FrameFil{k},1);
                    PathStats(n).AverageDis = -4;
                    if n == 1
                        set(hPathsStatsGui.rFilament,'Value',1); 
                    end
                end
                if Dis(1)>mean(Dis)
                    Dis=Dis*-1;
                    Side=Side*-1;
                end
                PathStats(n).PathData(:,1)=PathX;
                PathStats(n).PathData(:,2)=PathY;
                PathStats(n).PathData(:,3)=Dis;
                PathStats(n).PathData(:,4)=Side;    
                n=n+1;
            else
                PathStats(n)=[];
                Index(n)=[];
            end
        else
            PathStats(n).AverageDis(n)=-5;
            n=n+1;
        end
        h = findobj('Tag','timebar');
        if isempty(h)
            return
        end
        workbar((n-1)/nPathStats,'Calculating path','Progress',-1);     
        nPathStats = length(PathStats);
    end
    workbar(1,'Calculating path','Progress',-1);     
    setappdata(hPathsStatsGui.fig,'PathStats',PathStats);
    Draw(hPathsStatsGui);    
end
    
 function [xi,yi,fi]=InterpolFil(Filament)
nFil = length(Filament);
workbar(0,'Interpolating Filaments...','Progress',-1);
fi = cell(nFil,1);
for n = 1:nFil
    for m = 1:length(Filament(n).Data)
        X = Filament(n).Data{m}(:,1);
        Y = Filament(n).Data{m}(:,2);
        P = 1:length(X);
        pi = 1:0.01:length(X);
        xi{n,m} = interp1(P,X,pi); %#ok<AGROW>
        yi{n,m} = interp1(P,Y,pi); %#ok<AGROW>
    end
    fi{n} = Filament(n).Results(:,1);
    h = findobj('Tag','timebar');
    if isempty(h)
        return
    end
    workbar(n/nFil,'Interpolating Filaments...','Progress',-1);     
end

function [PathX,PathY,Dis,Side]=FilamentPath(Results,xi,yi,frames,GetDis)
nData = size(Results,1);
PathX = zeros(1,nData);
PathY = zeros(1,nData);
Dis = zeros(1,nData);
Side = zeros(1,nData);
for n = 1:size(Results,1)
    [~,k] = min(abs(Results(n,1)-frames));
    idx = k(1);
    X = xi{idx};
    Y = yi{idx};
    [m_dis,k] = min(sqrt( (Results(n,3)-X).^2+ (Results(n,4)-Y).^2));
    k = k(1);
    Side(n) = -m_dis*sum(sign(cross([X(k)-X(1) Y(k)-Y(1) 0],[Results(n,3)-X(k) Results(n,4)-Y(k) 0])));
    if Side(n) == 0
        Side(n) = m_dis;
    end
    if GetDis==1 
        PathX(n) = X(k);
        PathY(n) = Y(k);
        if length(frames)>1
            if n>1
                Dis(n) = Dis(n-1) + norm([PathX(n)-PathX(n-1) PathY(n)-PathY(n-1)]);
            end
        else
            for m = 2:k
                Dis(n) = Dis(n) + norm([X(m)-X(m-1) Y(m)-Y(m-1)]);
            end
        end

    end
end

function Ok(hPathsStatsGui)
global Molecule;
global Filament;
global Index;
PathStats=getappdata(hPathsStatsGui.fig,'PathStats');

for n=1:length(PathStats)
    if isreal(Index(n))
        idx = real(Index(n));
        Molecule(idx).PathData = PathStats(n).PathData;
    else
        idx = imag(Index(n));
        Filament(idx).PathData = PathStats(n).PathData;
    end
end
close(hPathsStatsGui.fig);
    
function Cancel(hPathsStatsGui)
close(hPathsStatsGui.fig);


function Load(hPathsStatsGui)
PathStats=getappdata(hPathsStatsGui.fig,'PathStats');
[FileName, PathName] = uigetfile({'*.mat','FIESTA Path(*.mat)'},'Load FIESTA Path',fShared('GetLoadDir'));
if FileName~=0
    fShared('SetLoadDir',PathName);
    temp_PathStats = fLoad([PathName FileName],'PathStats');
    PathStats = [PathStats temp_PathStats];     
    set(hPathsStatsGui.rLinear,'Value',0);                       
    set(hPathsStatsGui.rAverage,'Value',0);                       
    set(hPathsStatsGui.rPoly2,'Value',0);    
    set(hPathsStatsGui.rPoly3,'Value',0);  
    set(hPathsStatsGui.eAverage,'Enable','off'); 
    set(hPathsStatsGui.tNM,'Enable','off');
    if PathStats(1).AverageDis == -1
        set(hPathsStatsGui.rLinear,'Value',1);                       
    elseif PathStats(1).AverageDis == -2
        set(hPathsStatsGui.rPoly2,'Value',1);   
    elseif PathStats(1).AverageDis == -3
        set(hPathsStatsGui.rPoly3,'Value',1); 
    elseif PathStats(1).AverageDis > 0
        set(hPathsStatsGui.rAverage,'Value',1);          
        set(hPathsStatsGui.eAverage,'Enable','on','String',num2str(PathStats(1).AverageDis)); 
        set(hPathsStatsGui.tNM,'Enable','on');
    end
    set(hPathsStatsGui.lAll,'String',{PathStats.Name},'Value',1,'Max',length(PathStats));  
    set(hPathsStatsGui.cDrift,'Value',PathStats(1).Drift);   
    setappdata(hPathsStatsGui.fig,'PathStats',PathStats);
    Draw(hPathsStatsGui);
end    


function Save(hPathsStatsGui)
PathStats=getappdata(hPathsStatsGui.fig,'PathStats');
Mode=get(gcbo,'UserData');
if strcmp(Mode,'mat');
    [FileName, PathName] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save FIESTA Path',fShared('GetSaveDir'));
    fShared('SetSaveDir',PathName);
    file = [PathName FileName];
    if isempty(findstr('.mat',file))
        file = [file '.mat'];
    end
    hMainGui = getappdata(0,'hMainGui');
    Config = getappdata(hMainGui.fig,'Config'); %#ok<NASGU>
    save(file,'PathStats','Config');
else
    if strcmp(Mode,'single');
        [FileName, PathName] = uiputfile({'*.txt','Delimeted Text (*.txt)'}, 'Save FIESTA Tracks as...',fShared('GetSaveDir'));
        file = [PathName FileName];
        if FileName~=0
            if isempty(findstr('.txt',file))
                file = [file '.txt'];
            end        
            f = fopen(file,'w');
        end
    else
        PathName=uigetdir(fShared('GetSaveDir'));
    end
    if PathName~=0
        fShared('SetSaveDir',PathName);
        for n = 1:length(PathStats)
            if strcmp(Mode,'multiple')
                file=[PathName filesep PathStats(n).Name '.txt'];
                f = fopen(file,'w');
            end
            fprintf(f,'%s - %s%s\n',PathStats(n).Name,PathStats(n).Directory,PathStats(n).File);
            fprintf(f,'frame\ttime[s]\tx-position[nm]\ty-position[nm]\tdistance(to origin)[nm]\tamplitude[ABU]\tpath x-position[nm]\tpath y-Position[nm]\tdistance(along path)[nm]\tsideways(to path)[nm]\n');
            fprintf(f,num2str([PathStats(n).Results(:,1:5) PathStats(n).Results(:,7) PathStats(n).PathData]));
            fprintf(f,'\n'); 
            if strcmp(Mode,'multiple')
                fclose(f);
            end
        end
        if strcmp(Mode,'single')
            fclose(f);
        end
    end
end

function Update(hPathsStatsGui)
global Filament;
global Index;
n=get(hPathsStatsGui.lAll,'Value');
PathStats=getappdata(hPathsStatsGui.fig,'PathStats');
if gcbo==hPathsStatsGui.rFilament && ~isreal(Index(n))
    set(hPathsStatsGui.rFilament,'Value',0);  
    return;
end
set(hPathsStatsGui.rLinear,'Value',0);                       
set(hPathsStatsGui.rAverage,'Value',0);                       
set(hPathsStatsGui.rPoly2,'Value',0);    
set(hPathsStatsGui.rPoly3,'Value',0);  
set(hPathsStatsGui.rFilament,'Value',0);  
set(hPathsStatsGui.eAverage,'Enable','off'); 
set(hPathsStatsGui.tRegion,'Enable','off');
set(hPathsStatsGui.tNM,'Enable','off');
if gcbo==hPathsStatsGui.rLinear
    set(hPathsStatsGui.rLinear,'Value',1);                       
elseif gcbo==hPathsStatsGui.rPoly2
    set(hPathsStatsGui.rPoly2,'Value',1);   
elseif gcbo==hPathsStatsGui.rPoly3
    set(hPathsStatsGui.rPoly3,'Value',1); 
elseif gcbo==hPathsStatsGui.rFilament
    set(hPathsStatsGui.rFilament,'Value',1);     
elseif gcbo==hPathsStatsGui.rAverage
    set(hPathsStatsGui.rAverage,'Value',1);          
    set(hPathsStatsGui.eAverage,'Enable','on','String',''); 
    set(hPathsStatsGui.tNM,'Enable','on');
    set(hPathsStatsGui.tRegion,'Enable','on');
    return
end
if gcbo==hPathsStatsGui.lAll||gcbo==hPathsStatsGui.bReset||gcbo==hPathsStatsGui.bDisregard
    i=n(1);
    if gcbo==hPathsStatsGui.bDisregard
        PathStats(i)=[];
        Index(i)=[];
        if isempty(PathStats)
            delete(hPathsStatsGui.fig);
            return;
        end
        if i>length(PathStats)
            i=length(PathStats);
            set(hPathsStatsGui.lAll,'Value',i);
        end
        set(hPathsStatsGui.lAll,'String',{PathStats.Name});
        setappdata(hPathsStatsGui.fig,'PathStats',PathStats);
    end
    if PathStats(i).AverageDis==-1
        set(hPathsStatsGui.rLinear,'Value',1);    
    elseif PathStats(i).AverageDis==-2
        set(hPathsStatsGui.rPoly2,'Value',1);   
    elseif PathStats(i).AverageDis==-3
        set(hPathsStatsGui.rPoly3,'Value',1);
    elseif PathStats(i).AverageDis==-4
        set(hPathsStatsGui.rFilament,'Value',1);        
    elseif PathStats(i).AverageDis>0
        set(hPathsStatsGui.rAverage,'Value',1);          
        set(hPathsStatsGui.eAverage,'Enable','on','String',num2str(PathStats(i).AverageDis)); 
        set(hPathsStatsGui.tNM,'Enable','on');   
    end    
    hPathsStatsGui.Zoom.currentXY = [];
    Draw(hPathsStatsGui);
else
    cla(hPathsStatsGui.aPlotXY);
    set(hPathsStatsGui.aPlotXY,'Visible','off');   
    set(hPathsStatsGui.tCalcPath,'Visible','on');
    drawnow;
    for i = n
        X=double(PathStats(i).Results(:,3));
        Y=double(PathStats(i).Results(:,4));    
        if gcbo==hPathsStatsGui.bAuto
            [param1,resnorm1]=PathFitLinear(X,Y); 
            [PathX,PathY,Dis,Side]=LinearPath(X,Y,param1);
            try
                [param2,resnorm2]=PathFitPoly2(X,Y,Side,param1); 
            catch
                resnorm2 = Inf;
            end
            try
                [param3,resnorm3]=PathFitPoly3(X,Y,Side,param1); 
            catch
                resnorm3 = Inf;
            end
            if all(resnorm1<[resnorm2 resnorm3])
                set(hPathsStatsGui.rLinear,'Value',1);  
                PathStats(i).AverageDis=-1;
            elseif all(resnorm2<[resnorm1 resnorm3])
                [PathX,PathY,Dis,Side]=Poly2Path(X,Y,param2);
                PathStats(i).AverageDis=-2;
                set(hPathsStatsGui.rPoly2,'Value',1);   
            elseif all(resnorm3<[resnorm1 resnorm2])
                [PathX,PathY,Dis,Side]=Poly3Path(X,Y,param3);
                PathStats(i).AverageDis=-3;
                set(hPathsStatsGui.rPoly3,'Value',1); 
            end
        else
            if get(hPathsStatsGui.rLinear,'Value')==1
                [param,resnorm]=PathFitLinear(X,Y); %#ok<NASGU>
                [PathX,PathY,Dis,Side]=LinearPath(X,Y,param);
                PathStats(i).AverageDis=-1;
            elseif get(hPathsStatsGui.rPoly2,'Value')==1
                [param,resnorm]=PathFitLinear(X,Y); %#ok<NASGU>
                [~,~,~,Side]=LinearPath(X,Y,param);
                try
                    [param,resnorm]=PathFitPoly2(X,Y,Side,param); %#ok<NASGU>
                    [PathX,PathY,Dis,Side]=Poly2Path(X,Y,param);
                catch
                    fMsgDlg('Could not fit a 2nd deg polynomial path','error');
                    set(gcbo,'Value',0)
                    return;
                end
                PathStats(i).AverageDis=-2;
            elseif get(hPathsStatsGui.rPoly3,'Value')==1
                [param,resnorm]=PathFitLinear(X,Y); %#ok<NASGU>
                [~,~,~,Side]=LinearPath(X,Y,param);
                try
                    [param,resnorm]=PathFitPoly3(X,Y,Side,param); %#ok<NASGU>
                    [PathX,PathY,Dis,Side]=Poly3Path(X,Y,param);  
                catch
                    fMsgDlg('Could not fit a 3rd deg polynomial path','error');
                    set(gcbo,'Value',0)
                    return;
                end
                PathStats(i).AverageDis=-3;
             elseif get(hPathsStatsGui.rFilament,'Value')==1
                XPosFil = getappdata(hPathsStatsGui.fig,'XPosFil');
                YPosFil = getappdata(hPathsStatsGui.fig,'YPosFil');
                FrameFil = getappdata(hPathsStatsGui.fig,'FrameFil');
                if isempty(XPosFil)
                    [XPosFil,YPosFil,FrameFil]=InterpolFil(Filament);
                end
                nFil = size(XPosFil,1);
                if nFil > 1
                    s = zeros(nFil,1);
                    for m = 1:nFil
                        [~,~,~,Side] = FilamentPath(PathStats(n).Results,XPosFil(m,:),YPosFil(m,:),FrameFil{m},0);
                        s(m) = mean(abs(Side));
                    end
                    [~,k] = min(s);
                else
                    k = 1;
                end
                [PathX,PathY,Dis,Side]=FilamentPath(PathStats(n).Results,XPosFil(k,:),YPosFil(k,:),FrameFil{k},1);
                PathStats(n).AverageDis = -4;
            else
                if ~isempty(get(hPathsStatsGui.eAverage,'String'))
                    [PathX,PathY,Dis,Side] = AveragePath(PathStats(i).Results(:,1:4),round(str2double(get(hPathsStatsGui.eAverage,'String'))));
                    PathStats(i).AverageDis = round(str2double(get(hPathsStatsGui.eAverage,'String')));
                    set(hPathsStatsGui.eAverage,'Enable','on');     
                    set(hPathsStatsGui.rAverage,'Value',1);   
                else
                    Dis = [];
                end
            end
        end
        if ~isempty(Dis)
            if Dis(1)>mean(Dis)
                Dis=Dis*-1;
                Side=Side*-1;
            end
            Dis=Dis-Dis(1);
            PathStats(i).PathData(:,1)=PathX;
            PathStats(i).PathData(:,2)=PathY;
            PathStats(i).PathData(:,3)=Dis;
            PathStats(i).PathData(:,4)=Side;   
        end
    end
    if ~isempty(PathStats)
        setappdata(hPathsStatsGui.fig,'PathStats',PathStats);
        Draw(hPathsStatsGui);    
    end
end

function Draw(hPathsStatsGui)
set(0,'CurrentFigure',hPathsStatsGui.fig);    
set(hPathsStatsGui.tCalcPath,'Visible','off');
set(hPathsStatsGui.aPlotXY,'Visible','on');   
set(hPathsStatsGui.fig,'CurrentAxes',hPathsStatsGui.aPlotXY);
PathStats=getappdata(hPathsStatsGui.fig,'PathStats');
idx=get(hPathsStatsGui.lAll,'Value');
idx=idx(1);
XPlotPath = PathStats(idx).PathData(:,1)-min(PathStats(idx).Results(:,3));
YPlotPath = PathStats(idx).PathData(:,2)-min(PathStats(idx).Results(:,4));
Dis = PathStats(idx).PathData(:,3);
XPlot = PathStats(idx).Results(:,3)-min(PathStats(idx).Results(:,3));
YPlot = PathStats(idx).Results(:,4)-min(PathStats(idx).Results(:,4));
if (max(XPlot)-min(XPlot)) > 5000 || (max(YPlot)-min(YPlot)) > 5000
    xscale=1000;
    yscale=1000;
    units='[µm]';
else
    xscale=1;
    yscale=1;
    units='[nm]';
end
data = [Dis XPlotPath YPlotPath];
data = sortrows(data,1);
XPlotPath = data(:,2)';
YPlotPath = data(:,3)';
plot(hPathsStatsGui.aPlotXY,XPlot/xscale,YPlot/yscale,'Color','blue','LineStyle','-','Marker','*');
line(XPlotPath/xscale,YPlotPath/yscale,'Color','green','LineStyle','-','Marker','none');
if isempty(hPathsStatsGui.Zoom.currentXY)
    SetAxis(hPathsStatsGui.aPlotXY,XPlot/xscale,YPlot/yscale);
    hPathsStatsGui.Zoom.globalXY = get(hPathsStatsGui.aPlotXY,{'xlim','ylim'});
    hPathsStatsGui.Zoom.currentXY = hPathsStatsGui.Zoom.globalXY;
    hPathsStatsGui.Zoom.level = 0;
else
    set(hPathsStatsGui.aPlotXY,{'xlim','ylim'},hPathsStatsGui.Zoom.currentXY,'YDir','reverse');
end
xlabel(hPathsStatsGui.aPlotXY,['X-Position  ' units]);
ylabel(hPathsStatsGui.aPlotXY,['Y-Position  ' units]);

set(hPathsStatsGui.fig,'CurrentAxes',hPathsStatsGui.aPlotDist);
XPlot = PathStats(idx).Results(:,2);
YPlot = Dis;
YPlotOld = PathStats(idx).Results(:,5);
if (max(YPlot)-min(YPlot)) > 5000 || (max(YPlotOld)-min(YPlotOld)) > 5000
    yscale=1000;
    units='[µm]';
else
    yscale=1;
    units='[nm]';
end 
plot(hPathsStatsGui.aPlotDist,XPlot,YPlotOld/yscale,'Color','red','LineStyle','--','Marker','none');
line(XPlot,YPlot/yscale,'Color','blue','LineStyle','-','Marker','none');
xlabel(hPathsStatsGui.aPlotDist,'Time [sec]');
ylabel(hPathsStatsGui.aPlotDist,['Distance along path ' units]);

set(hPathsStatsGui.fig,'CurrentAxes',hPathsStatsGui.aPlotSide);
XPlot = PathStats(idx).Results(:,2);
YPlot = PathStats(idx).PathData(:,4);
if (max(YPlot)-min(YPlot)) > 1000
    yscale=1000;
    units='[µm]';
else
    yscale=1;
    units='[nm]';
end 
plot(hPathsStatsGui.aPlotSide,XPlot,YPlot/yscale,'Color','green','LineStyle','-','Marker','none');
xlabel(hPathsStatsGui.aPlotSide,'Time [sec]');
ylabel(hPathsStatsGui.aPlotSide,['Sideways motion ' units]);
setappdata(0,'hPathsStatsGui',hPathsStatsGui);

function SetAxis(a,X,Y)
set(a,'Units','pixel');
pos=get(a,'Position');
set(a,'Units','normalized');
xy{1}=[-ceil(max(-X)) ceil(max(X))];
xy{2}=[-ceil(max(-Y)) ceil(max(Y))];
if all(~isnan(xy{1}))&&all(~isnan(xy{2}))
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
end

function Drift(hPathsStatsGui)
PathStats=getappdata(hPathsStatsGui.fig,'PathStats');
hMainGui=getappdata(0,'hMainGui');
Drift=getappdata(hMainGui.fig,'Drift');
if ~isempty(Drift)
    for n = 1:length(PathStats)
        if get(hPathsStatsGui.cDrift,'Value') == 1 && PathStats(n).Drift == 0
            t = -1; %subtract drift
        elseif get(hPathsStatsGui.cDrift,'Value') == 0 && PathStats(n).Drift == 1
            t = 1; %add drift
        else
            t = 0;
        end 
        nData=size(PathStats(n).Results,1);
        for i=1:nData
            k=find(Drift(:,1)==PathStats(n).Results(i,1));
            if length(k)==1
                 PathStats(n).Results(n,3:4) = single( PathStats(n).Results(n,3:4) + t*Drift(k,2:3) );
            end
        end
        PathStats(n).Results(:,5) = fDis( PathStats(n).Results(:,3:4) );
        PathStats(n).Drift = get(hPathsStatsGui.cDrift,'Value');
    end
    setappdata(hPathsStatsGui.fig,'PathStats',PathStats);
    Update(hPathsStatsGui)
    Draw(hPathsStatsGui,0);
end

function res=LinearModel(param,X,Y)
Proj=(X-param(1))*sin(param(3)) + (Y-param(2))*cos(param(3));
res=( X - (sin(param(3))*Proj+param(1)) ).^2 + ( Y - (cos(param(3))*Proj+param(2))).^2;

function [param,resnorm]=PathFitLinear(X,Y)
param0(1)=X(1)+(X(length(X))-X(1))/2;
param0(2)=Y(1)+(Y(length(Y))-Y(1))/2;
param0(3)=atan( (X(length(X))-X(1))/(Y(length(Y))-Y(1)));
options = optimset('Display','off');
try
    [param,resnorm,~,~,output]= lsqnonlin(@LinearModel,param0,[],[],options,X,Y); %#ok<NASGU>
catch %#ok<CTCH>
    param=param0;
    resnorm=1e100;
end

function [PathX,PathY,Dis,Side]=LinearPath(X,Y,param)
Proj=(X-param(1))*sin(param(3)) + (Y-param(2))*cos(param(3));
Dis=Proj-Proj(1);
v=[X-(sin(param(3))*Proj+param(1)) Y-(cos(param(3))*Proj+param(2)) zeros(length(Proj),1)];
u=[(sin(param(3))*Proj+param(1))-(sin(param(3))*(min(Proj)-1)+param(1)) (cos(param(3))*Proj+param(2))-(cos(param(3))*(min(Proj)-1)+param(2)) zeros(length(Proj),1)];
Side=sqrt( v(:,1).^2 + v(:,2).^2 ).*-sum(sign(cross(u,v)),2);
Side(isnan(Side))=0;
PathX=(sin(param(3))*Proj+param(1));
PathY=(cos(param(3))*Proj+param(2));

function res=Poly2Model(param,X,Y)
c3 = 2*param(4)^2;
c2 = 0;
c1 = (2*(param(1)-X)*param(4)*cos(param(3))+2*(Y-param(2))*param(4)*sin(param(3))+1)/c3;
c0 = ((param(1)-X)*sin(param(3))+(param(2)-Y)*cos(param(3)))/c3;
p = (3*c1-c2^2)/3;
q = (9*c1*c2-27*c0-2*c2^3)/27; 
Q=(1/3)*p;
R=(1/2)*q;
D=Q.^3+R.^2;
k=find(D>=0);
S=zeros(length(D),1);
T=zeros(length(D),1);
S(k)=nthroot(R(k)+sqrt(D(k)),3);
T(k)=nthroot(R(k)-sqrt(D(k)),3);
root=zeros(length(D),1);
root(k,1) = -(1/3)*c2+(S(k)+T(k));
root(k,2) = -(1/3)*c2-(1/2)*(S(k)+T(k))+(1/2)*1i*sqrt(3)*(S(k)-T(k));
root(k,3) = -(1/3)*c2-(1/2)*(S(k)+T(k))-(1/2)*1i*sqrt(3)*(S(k)-T(k));
k=find(D<0);
phi=zeros(length(D),3);
phi(k)=acos(R(k)./sqrt(-Q(k).^3));
root(k,1) = 2*sqrt(-Q(k)).*cos(phi(k)/3)-(1/3)*c2;
root(k,2) = 2*sqrt(-Q(k)).*cos((phi(k)+2*pi)/3)-(1/3)*c2;
root(k,3) = 2*sqrt(-Q(k)).*cos((phi(k)+4*pi)/3)-(1/3)*c2;
root(imag(root)~=0)=NaN;
W=sqrt(([X X X]-(sin(param(3))*root+param(1)+root.^2*param(4)*cos(param(3)))).^2+([Y Y Y]-(cos(param(3))*root+param(2)-root.^2*param(4)*sin(param(3)))).^2);
[~,lx]=min(W,[],2);
Proj=root(sub2ind([length(X) 3],(1:length(X))',lx));
res=( X - (sin(param(3))*Proj+param(1)+Proj.^2*param(4)*cos(param(3)))).^2 + ( Y - (cos(param(3))*Proj+param(2)-Proj.^2*param(4)*sin(param(3)))).^2;

function [param,resnorm]=PathFitPoly2(X,Y,Side,param)
Proj=(X-param(1))*sin(param(3)) + (Y-param(2))*cos(param(3));
fd=fit(Proj,Side,'poly2');
x0=-fd.p2/(2*fd.p1);
y0=fd.p1*x0^2+fd.p2*x0+fd.p3;
param0(1)=sin(param(3))*x0+param(1)+y0*cos(param(3));
param0(2)=cos(param(3))*x0+param(2)-y0*sin(param(3));
param0(3)=param(3);
param0(4)=fd.p1;
options = optimset('Display','off');%optimget('MaxFunEvals',400,'MaxIter',300,'TolFun',1e-3,'TolX',1e-3,'LargeScale','on');
[param,resnorm,~,~,output]= lsqnonlin(@Poly2Model,param0,[],[],options,X,Y); %#ok<NASGU>


function [PathX,PathY,Dis,Side]=Poly2Path(X,Y,param)
c3 = 2*param(4)^2;
c2 = 0;
c1 = (2*(param(1)-X)*param(4)*cos(param(3))+2*(Y-param(2))*param(4)*sin(param(3))+1)/c3;
c0 = ((param(1)-X)*sin(param(3))+(param(2)-Y)*cos(param(3)))/c3;
p = (3*c1-c2^2)/3;
q = (9*c1*c2-27*c0-2*c2^3)/27; 
Q=(1/3)*p;
R=(1/2)*q;
D=Q.^3+R.^2;
k=find(D>=0);
S=zeros(length(D),1);
T=zeros(length(D),1);
S(k)=nthroot(R(k)+sqrt(D(k)),3);
T(k)=nthroot(R(k)-sqrt(D(k)),3);
root=zeros(length(D),1);
root(k,1) = -(1/3)*c2+(S(k)+T(k));
root(k,2) = -(1/3)*c2-(1/2)*(S(k)+T(k))+(1/2)*1i*sqrt(3)*(S(k)-T(k));
root(k,3) = -(1/3)*c2-(1/2)*(S(k)+T(k))-(1/2)*1i*sqrt(3)*(S(k)-T(k));
k=find(D<0);
phi=zeros(length(D),3);
phi(k)=acos(R(k)./sqrt(-Q(k).^3));
root(k,1) = 2*sqrt(-Q(k)).*cos(phi(k)/3)-(1/3)*c2;
root(k,2) = 2*sqrt(-Q(k)).*cos((phi(k)+2*pi)/3)-(1/3)*c2;
root(k,3) = 2*sqrt(-Q(k)).*cos((phi(k)+4*pi)/3)-(1/3)*c2;
root(imag(root)~=0)=NaN;
W=sqrt(([X X X]-(sin(param(3))*root+param(1)+root.^2*param(4)*cos(param(3)))).^2+([Y Y Y]-(cos(param(3))*root+param(2)-root.^2*param(4)*sin(param(3)))).^2);
[~,lx]=min(W,[],2);
Proj=root(sub2ind([length(D) 3],(1:length(D))',lx));
Dis=zeros(length(X),1);
for i = 2:length(X)
    if i>1
        F = @(t)sqrt( (sin(param(3))+2*t*param(4)*cos(param(3))).^2+(cos(param(3))-2*t*param(4)*sin(param(3))).^2);
        Dis(i) = quad(F,Proj(1),Proj(i)); 
    end
end
v=[X-(sin(param(3))*Proj+Proj.^2*param(4)*cos(param(3))+param(1)) Y-(cos(param(3))*Proj-Proj.^2*param(4)*sin(param(3))+param(2)) zeros(length(Proj),1)];
u=[(sin(param(3))*Proj+Proj.^2*param(4)*cos(param(3))+param(1))-(sin(param(3))*(min(Proj)-1)+(min(Proj)-1).^2*param(4)*cos(param(3))+param(1))...
   (cos(param(3))*Proj-Proj.^2*param(4)*sin(param(3))+param(2))-(cos(param(3))*(min(Proj)-1)-(min(Proj)-1).^2*param(4)*sin(param(3))+param(2)) zeros(length(Proj),1)];
Side=sqrt( v(:,1).^2 + v(:,2).^2 ).*-sum(sign(cross(u,v)),2);
PathX=(sin(param(3))*Proj+Proj.^2*param(4)*cos(param(3))+param(1));
PathY=(cos(param(3))*Proj-Proj.^2*param(4)*sin(param(3))+param(2));

function res=Poly3Model(param,X,Y)
c5 = 3*param(5)^2;
c4 = 5*param(4)*param(5);
c3 = 2*param(4)^2;
c2 = (param(1)-X)*3*param(5)*cos(param(3))+(Y-param(2))*3*param(5)*sin(param(3));
c1 = (2*(param(1)-X)*param(4)*cos(param(3))+2*(Y-param(2))*param(4)*sin(param(3))+1);
c0 = ((param(1)-X)*sin(param(3))+(param(2)-Y)*cos(param(3)));
root=zeros(length(X),5);
for i=1:length(X)
    root(i,:)=roots([c5 c4 c3 c2(i) c1(i) c0(i)])';
end
root(imag(root)~=0)=NaN;
W=sqrt(([X X X X X]-(sin(param(3))*root+param(1)+(root.^2*param(4)+root.^3*param(5))*cos(param(3)))).^2+([Y Y Y Y Y]-(cos(param(3))*root+param(2)-(root.^2*param(4)+root.^3*param(5))*sin(param(3)))).^2);
[~,lx]=min(W,[],2);
Proj=root(sub2ind([length(X) 5],(1:length(X))',lx));
res=( X - (sin(param(3))*Proj+param(1)+(Proj.^2*param(4)+Proj.^3*param(5))*cos(param(3)))).^2 + ( Y - (cos(param(3))*Proj+param(2)-(Proj.^2*param(4)+Proj.^3*param(5))*sin(param(3)))).^2;

function [param,resnorm]=PathFitPoly3(X,Y,Side,param)
Proj=(X-param(1))*sin(param(3)) + (Y-param(2))*cos(param(3));
[p,~,m]=polyfit(Proj,Side,3);
x0=(-2*p(2)+[sqrt(4*p(2)^2-12*p(1)*p(3)) -sqrt(4*p(2)^2-12*p(1)*p(3))])/(6*p(1));
if (p(1)>0&&p(2)>=0)||(p(1)<0&&p(2)<=0)
    if isreal(max(x0))
        x0=max(x0);
    else
        x0=min(x0);        
    end
else
   if isreal(min(x0))
        x0=min(x0);
    else
        x0=max(x0);        
    end
end
y0=polyval(p,x0);
x0=x0*m(2)+m(1);
Side=Side-y0;
Proj=Proj-x0;
F=fittype('p1*x^3+p2*x^2','coefficients',{'p1','p2'});
fd=fit(Proj,Side,F,'Startpoint',[1 1]);
param0(1)=sin(param(3))*x0+param(1)+y0*cos(param(3));
param0(2)=cos(param(3))*x0+param(2)-y0*sin(param(3));
param0(3)=param(3);
param0(4)=fd.p2;
param0(5)=fd.p1;
options = optimset('Display','off');
[param,resnorm,~,~,output]= lsqnonlin(@Poly3Model,param0,[],[],options,X,Y); %#ok<NASGU>


function [PathX,PathY,Dis,Side]=Poly3Path(X,Y,param)
c5 = 3*param(5)^2;
c4 = 5*param(4)*param(5);
c3 = 2*param(4)^2;
c2 = (param(1)-X)*3*param(5)*cos(param(3))+(Y-param(2))*3*param(5)*sin(param(3));
c1 = (2*(param(1)-X)*param(4)*cos(param(3))+2*(Y-param(2))*param(4)*sin(param(3))+1);
c0 = ((param(1)-X)*sin(param(3))+(param(2)-Y)*cos(param(3)));
Proj=zeros(length(X),1);
Dis=zeros(length(X),1);
for i=1:length(X)
    root=roots([c5 c4 c3 c2(i) c1(i) c0(i)])';
    root(imag(root)~=0)=NaN;
    W=sqrt(([X(i) X(i) X(i) X(i) X(i)]-(sin(param(3))*root+param(1)+(root.^2*param(4)+root.^3*param(5))*cos(param(3)))).^2+([Y(i) Y(i) Y(i) Y(i) Y(i)]-(cos(param(3))*root+param(2)-(root.^2*param(4)+root.^3*param(5))*sin(param(3)))).^2);
    [~,lx]=min(W);
    Proj(i)=root(lx);
    if i>1
        F = @(t)sqrt( (sin(param(3))+(2*t*param(4)+3*t.^2*param(5))*cos(param(3))).^2+(cos(param(3))-(2*t*param(4)+3*t.^2*param(5))*sin(param(3))).^2);
        Dis(i) = quad(F,Proj(1),Proj(i)); 
    end
end
v=[X-(sin(param(3))*Proj+(Proj.^2*param(4)+Proj.^3*param(5))*cos(param(3))+param(1)) Y-(cos(param(3))*Proj-(Proj.^2*param(4)+Proj.^3*param(5))*sin(param(3))+param(2)) zeros(length(Proj),1)];
u=[(sin(param(3))*Proj+(Proj.^2*param(4)+Proj.^3*param(5))*cos(param(3))+param(1))-(sin(param(3))*(min(Proj)-1)+((min(Proj)-1).^2*param(4)+(min(Proj)-1).^3*param(5))*cos(param(3))+param(1))...
   (cos(param(3))*Proj-(Proj.^2*param(4)+Proj.^3*param(5))*sin(param(3))+param(2))-(cos(param(3))*(min(Proj)-1)-((min(Proj)-1).^2*param(4)+(min(Proj)-1).^3*param(5))*sin(param(3))+param(2)) zeros(length(Proj),1)];
u(:,1)=u(:,1)./sqrt(u(:,1).^2+u(:,2).^2);
u(:,2)=u(:,2)./sqrt(u(:,1).^2+u(:,2).^2);
Side=sqrt( v(:,1).^2 + v(:,2).^2 ).*-sum(sign(cross(u,v)),2);
PathX=(sin(param(3))*sort(Proj)+(sort(Proj).^2*param(4)+sort(Proj).^3*param(5))*cos(param(3))+param(1));
PathY=(cos(param(3))*sort(Proj)-(sort(Proj).^2*param(4)+sort(Proj).^3*param(5))*sin(param(3))+param(2));

function [X,Y,Dis,Side]=AveragePath(Results,DisRegion)
nData=size(Results,1);
NRes(1,1:3)=Results(1,2:4);
p=2;
n=1;
b=true(1);
while n<=nData
    IN = sqrt( (Results(n,3)-Results(:,3)).^2+(Results(n,4)-Results(:,4)).^2)<DisRegion;
    if sum(IN)==1
        NRes(p,1:3) = Results(n,2:4);
        n = n+1;
    else
        k = find(~IN);
        k_start = k(find(k<n,1,'last'))+1;
        k_end = k(find(k>n,1,'first'))-1;
        if isempty(k_start)
            k_start=1;
        end
        if isempty(k_end)
            k_end=nData;
        end
        NRes(p,1) = mean(Results(k_start:k_end,2));
        NRes(p,2) = mean(Results(k_start:k_end,3));
        NRes(p,3) = mean(Results(k_start:k_end,4));
        n = k_end+1;
        if n>nData
            if b && k_end-k_start+1<nData
                n=nData;
                b=false(1);
            end
        end
    end
    p=p+1;
end
NRes(p,1:3)=Results(nData,2:4);
NRes(1,4) = atan2( NRes(2,3) - NRes(1,3), NRes(2,2) - NRes(1,2) );
for n = 2:p-1
    NRes(n,4) = mean([atan2( NRes(n+1,3) - NRes(n,3), NRes(n+1,2) - NRes(n,2) ) atan2( NRes(n,3) - NRes(n-1,3), NRes(n,2) - NRes(n-1,2) )]);
end
NRes(p,4) = atan2( NRes(p,3) - NRes(p-1,3), NRes(p,2) - NRes(p-1,2) );
 
seg_length = zeros( 1, size( NRes , 1 ) );  %<< the length start of each segment on the filament
x_coeff = zeros( size( NRes , 1 ) - 1, 3 ); %<< the 3 coefficients for the interpolation in x-direction for each segment
y_coeff = zeros( size( NRes , 1 ) - 1, 3 ); %<< the 3 coefficients for the interpolation in y-direction for each segment

% run through all sections
p = 1;
while p < size( NRes , 1 ) % run through all points but the last one
        
    % get the two points in question
    s = NRes(p,:);
    e = NRes(p+1,:);

    if all( s(1:3) == e(1:3) ) % identical points (this should not happen though) => ignore
        NRes(p,:) = [];
        seg_length(p+1) = [];
        x_coeff(p,:) = [];
        y_coeff(p,:) = [];
        continue
    else 
        % rotate space to get a real function
        rot = atan2( e(3) - s(3), e(2) - s(2) );
        d = ( e(2) - s(2) ) ./ cos( rot ); %<< distance between points        
    end

    % calculate the slope for the rotated version
    slope1 = tan( s(4) - rot );
    slope2 = tan( e(4) - rot );

    % calculate cubic function coefficients (the formulas are derived in the
    % documentation (take non-matrix functions, because otherwise
    % double_error wont work
    c(1) = ( slope1 + slope2 ) ./ d.^2;
    c(2) = -( 2 * slope1 + slope2 ) ./ d;
    c(3) = slope1;

    % rotate back to get the real space cubic coefficients
    % and transform to have parameter in range [0 1]
    x_coeff(p,:) = [ -sin(rot)*c(1)*d.^3 -sin(rot)*c(2)*d.^2 (-sin(rot)*c(3)+cos(rot))*d ];
    y_coeff(p,:) = [  cos(rot)*c(1)*d.^3  cos(rot)*c(2)*d.^2 ( cos(rot)*c(3)+sin(rot))*d ];

    % calculate length segment without error - error will be determined later
    F = @(t)sqrt( (3*x_coeff(p,1)*t.^2 + 2*x_coeff(p,2)*t + x_coeff(p,3) ).^2 + ...
                  (3*y_coeff(p,1)*t.^2 + 2*y_coeff(p,2)*t + y_coeff(p,3) ).^2 );
                    
    length_integral = quad( F, 0, 1 ); %<< integrate arc length
        
    if length_integral == 0 % degenerated segment
        % delete point of object - this should happen very seldom, such that
        % it should be faster to preallocate memory for lists and delete
        % entries, if necessary.
        
        seg_length(end) = [];
        x_coeff(end,:) = [];
        y_coeff(end,:) = [];
        NRes(p,:);
          
    else
          
        % add segment length to list
        seg_length(p+1) = length_integral;
        p = p + 1; % step to next point
          
    end

end % of run through all sections
   
NRes=sortrows(NRes);
X = zeros(1,nData);
Y = zeros(1,nData);
Dis = zeros(1,nData);
Side = zeros(1,nData);
X(1) = NRes(1,2);
Y(1) = NRes(1,3);
for n = 2:nData-1
    
    k_before = find( NRes(:,1)<=Results(n,2),1,'last');
    k_after = find( NRes(:,1)>=Results(n,2),1,'first');
    
    while 1
        
        k=k_before;
        G = @(t)sqrt( (x_coeff(k,1)*t.^3 + x_coeff(k,2)*t.^2 + x_coeff(k,3)*t + NRes(k,2) - Results(n,3) ).^2 + ...
                     (y_coeff(k,1)*t.^3 + y_coeff(k,2)*t.^2 + y_coeff(k,3)*t + NRes(k,3) - Results(n,4) ).^2 );
              try
        [idx_before,m] = fminsearch( G, double((Results(n,2)-NRes(k,1))/(NRes(k+1,1)-NRes(k,1))) );
              catch
                 k 
              end
        
        if k_after < size(NRes,1)
            k=k_after;
            G = @(t)sqrt( (x_coeff(k,1)*t.^3 + x_coeff(k,2)*t.^2 + x_coeff(k,3)*t + NRes(k,2) - Results(n,3) ).^2 + ...
                         (y_coeff(k,1)*t.^3 + y_coeff(k,2)*t.^2 + y_coeff(k,3)*t + NRes(k,3) - Results(n,4) ).^2 );

            [idx_after,~] = fminsearch( G, double((Results(n,2)-NRes(k,1))/(NRes(k+1,1)-NRes(k,1))) );       
        else
            idx_after = NaN;
        end

     	if idx_before > 1 && idx_after > 0 && k_after < size(NRes,1)-1
            k_before = k_before + 1;
            k_after = k_after + 1;
        elseif idx_before < 0 && k_before > 1
            k_before = k_before - 1;
            k_after = k_after - 1;
        else 
            break
        end
    end
    
    k = k_before;
    idx = idx_before;
    F = @(t)sqrt( (3*x_coeff(k,1)*t.^2 + 2*x_coeff(k,2)*t + x_coeff(k,3) ).^2 + ...
                  (3*y_coeff(k,1)*t.^2 + 2*y_coeff(k,2)*t + y_coeff(k,3) ).^2 );
 
    X(n) = x_coeff(k,1)*idx.^3 + x_coeff(k,2)*idx.^2 + x_coeff(k,3)*idx + NRes(k,2);
    Y(n) = y_coeff(k,1)*idx.^3 + y_coeff(k,2)*idx.^2 + y_coeff(k,3)*idx + NRes(k,3);
    
    Dis(n) = sum(seg_length(1:k)) + quad( F, 0, idx ); 
    Side(n) = -m*sum(sign(cross([X(n)-NRes(k,2) Y(n)-NRes(k,3) 0],[Results(n,3)-X(n) Results(n,4)-Y(n) 0])));

end
X(nData) = NRes(end,2);
Y(nData) = NRes(end,3);
Dis(nData) = sum(seg_length);


function ButtonDown(hObject, eventdata) %#ok<INUSD>
hPathsStatsGui=getappdata(0,'hPathsStatsGui');
set(0,'CurrentFigure',hPathsStatsGui.fig);
set(hPathsStatsGui.fig,'CurrentAxes',hPathsStatsGui.aPlotXY);  
cp=get(hPathsStatsGui.aPlotXY,'currentpoint');
cp=cp(1,[1 2]);
pos = get(hPathsStatsGui.pPlotXYPanel,'Position');
cpFig = get(hPathsStatsGui.fig,'currentpoint');
cpFig = cpFig(1,[1 2]);
if all(cpFig>=[pos(1) pos(2)]) && all(cpFig<=[pos(1)+pos(3) pos(2)+pos(4)]) 
    if strcmp(get(hPathsStatsGui.fig,'SelectionType'),'normal')
        hPathsStatsGui.CursorMode='Normal';
    elseif strcmp(get(hPathsStatsGui.fig,'SelectionType'),'extend')
        hPathsStatsGui.CursorMode='Pan';
        hPathsStatsGui.CursorDownPos=cp;  
        CData=[NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,1,1,NaN,1,1,NaN,1,1,NaN,NaN,NaN,NaN;NaN,NaN,NaN,1,2,2,1,2,2,1,2,2,1,1,NaN,NaN;NaN,NaN,NaN,1,2,2,2,2,2,2,2,2,1,2,1,NaN;NaN,NaN,NaN,NaN,1,2,2,2,2,2,2,2,2,2,1,NaN;NaN,NaN,NaN,1,1,2,2,2,2,2,2,2,2,2,1,NaN;NaN,NaN,1,2,2,2,2,2,2,2,2,2,2,2,1,NaN;NaN,NaN,1,2,2,2,2,2,2,2,2,2,2,2,1,NaN;NaN,NaN,1,2,2,2,2,2,2,2,2,2,2,1,NaN,NaN;NaN,NaN,NaN,1,2,2,2,2,2,2,2,2,2,1,NaN,NaN;NaN,NaN,NaN,NaN,1,2,2,2,2,2,2,2,1,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,1,2,2,2,2,2,2,1,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,1,2,2,2,2,2,2,1,NaN,NaN,NaN;];
        set(hPathsStatsGui.fig,'Pointer','custom','PointerShapeCData',CData,'PointerShapeHotSpot',[10 9]);
    end
end
setappdata(0,'hPathsStatsGui',hPathsStatsGui);

function ButtonUp(hObject, eventdata) %#ok<INUSD>
hPathsStatsGui=getappdata(0,'hPathsStatsGui');
set(0,'CurrentFigure',hPathsStatsGui.fig);
set(hPathsStatsGui.fig,'CurrentAxes',hPathsStatsGui.aPlotXY);  
Check=getappdata(hPathsStatsGui.fig,'Check');
cpFig = get(hPathsStatsGui.fig,'currentpoint');
if strcmp(get(hPathsStatsGui.fig,'SelectionType'),'extend')
    hPathsStatsGui.CursorDownPos(:)=0;    
    hPathsStatsGui.CursorMode='Normal';
    set(hPathsStatsGui.fig,'pointer','arrow');
end
setappdata(0,'hPathsStatsGui',hPathsStatsGui);
setappdata(hPathsStatsGui.fig,'Check',Check);
Draw(hPathsStatsGui);


function UpdateCursor(hObject, eventdata) %#ok<INUSD>
hPathsStatsGui=getappdata(0,'hPathsStatsGui');
set(0,'CurrentFigure',hPathsStatsGui.fig);
set(hPathsStatsGui.fig,'CurrentAxes',hPathsStatsGui.aPlotXY);  
pos = get(hPathsStatsGui.pPlotXYPanel,'Position');
cpFig = get(hPathsStatsGui.fig,'currentpoint');
cpFig = cpFig(1,[1 2]);
cp=get(hPathsStatsGui.aPlotXY,'currentpoint');
cp=cp(1,[1 2]);
if all(cpFig>=[pos(1) pos(2)]) && all(cpFig<=[pos(1)+pos(3) pos(2)+pos(4)])
    if strcmp(hPathsStatsGui.CursorMode,'Normal')
        set(hPathsStatsGui.fig,'pointer','arrow');
    else
        if all(hPathsStatsGui.CursorDownPos~=0)
            Zoom=hPathsStatsGui.Zoom;
            xy=Zoom.currentXY;
            xy{1}=xy{1}-(cp(1)-hPathsStatsGui.CursorDownPos(1));
            xy{2}=xy{2}-(cp(2)-hPathsStatsGui.CursorDownPos(2));
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
            set(hPathsStatsGui.aPlotXY,{'xlim','ylim'},xy);
            hPathsStatsGui.Zoom.currentXY=xy;
        end
        CData=[NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,1,1,NaN,1,1,NaN,1,1,NaN,NaN,NaN,NaN;NaN,NaN,NaN,1,2,2,1,2,2,1,2,2,1,1,NaN,NaN;NaN,NaN,NaN,1,2,2,2,2,2,2,2,2,1,2,1,NaN;NaN,NaN,NaN,NaN,1,2,2,2,2,2,2,2,2,2,1,NaN;NaN,NaN,NaN,1,1,2,2,2,2,2,2,2,2,2,1,NaN;NaN,NaN,1,2,2,2,2,2,2,2,2,2,2,2,1,NaN;NaN,NaN,1,2,2,2,2,2,2,2,2,2,2,2,1,NaN;NaN,NaN,1,2,2,2,2,2,2,2,2,2,2,1,NaN,NaN;NaN,NaN,NaN,1,2,2,2,2,2,2,2,2,2,1,NaN,NaN;NaN,NaN,NaN,NaN,1,2,2,2,2,2,2,2,1,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,1,2,2,2,2,2,2,1,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,1,2,2,2,2,2,2,1,NaN,NaN,NaN;];
        set(hPathsStatsGui.fig,'Pointer','custom','PointerShapeCData',CData,'PointerShapeHotSpot',[10 9]);    
    end
    setappdata(0,'hPathsStatsGui',hPathsStatsGui);
else 
    set(hPathsStatsGui.fig,'pointer','arrow');
end

function Scroll(hObject,eventdata) %#ok<INUSL>
hPathsStatsGui=getappdata(0,'hPathsStatsGui');
set(0,'CurrentFigure',hPathsStatsGui.fig);
set(hPathsStatsGui.fig,'CurrentAxes',hPathsStatsGui.aPlotXY);  
pos = get(hPathsStatsGui.pPlotXYPanel,'Position');
cpFig = get(hPathsStatsGui.fig,'currentpoint');
cpFig = cpFig(1,[1 2]);
xy=get(hPathsStatsGui.aPlotXY,{'xlim','ylim'});
cp=get(hPathsStatsGui.aPlotXY,'currentpoint');
cp=cp(1,[1 2]);
if all(cpFig>=[pos(1) pos(2)]) && all(cpFig<=[pos(1)+pos(3) pos(2)+pos(4)])
    Zoom=hPathsStatsGui.Zoom;
    level=Zoom.level-eventdata.VerticalScrollCount;
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
        if (y_current/x_current) >= Zoom.aspect
            new_scale_y = y_total*p;
            new_scale_x = new_scale_y/Zoom.aspect;
        else
            new_scale_x = x_total*p;
            new_scale_y = new_scale_x*Zoom.aspect;
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
    set(hPathsStatsGui.aPlotXY,{'xlim','ylim'},Zoom.currentXY);
    hPathsStatsGui.Zoom=Zoom;
    setappdata(0,'hPathsStatsGui',hPathsStatsGui);
end