function fRightPanel(func,varargin)
switch func
    case 'UpdateMeasure'
        UpdateMeasure(varargin{1});
    case 'NewScan'
        NewScan(varargin{1});        
    case 'NewKymoGraph'
        NewKymoGraph(varargin{1});                
    case 'KymoFrames'
        KymoFrames(varargin{1});                        
    case 'UpdateLineScan'
        UpdateLineScan(varargin{1});                
    case 'DataPanel'
        DataPanel(varargin{1});        
    case 'ToolsPanel'
        ToolsPanel(varargin{1});
    case 'QueuePanel'
        QueuePanel(varargin{1});
    case 'DataMoleculesPanel'
        DataMoleculesPanel(varargin{1});     
    case 'DataFilamentsPanel'
        DataFilamentsPanel(varargin{1});          
    case 'ToolsMeasurePanel'
        ToolsMeasurePanel(varargin{1});     
    case 'ToolsScanPanel'
        ToolsScanPanel(varargin{1});   
    case 'QueueServerPanel'
        QueueServerPanel(varargin{1});     
    case 'QueueLocalPanel'
        QueueLocalPanel(varargin{1});   
    case 'ToggleTool'
        ToggleTool(varargin{1});
    case 'AllToolsOff'
        AllToolsOff(varargin{1});
    case 'MeasureTable'
        MeasureTable(varargin{1});
    case 'ScanSize'
        ScanSize(varargin{1});
    case 'ShowKymoGraph'
        ShowKymoGraph(varargin{1});
    case 'DeleteScan'
        DeleteScan(varargin{1});        
    case 'UpdateList'
        UpdateList(varargin{1},varargin{2},varargin{3},varargin{4});
    case 'ListSlider'
        ListSlider(varargin{1});
    case 'ListButton'
        ListButton(varargin{1},varargin{2});
    case 'ListVisible'
        ListVisible(varargin{1},varargin{2});
    case 'QueueCheck'
        QueueCheck(varargin{1});
    case 'UpdateQueue'
        UpdateQueue(varargin{1});
    case 'QueueSlider'
        QueueSlider;        
    case 'ShowAllFil'
        ShowAllFil(varargin{1});        
    case 'SubtractDrift'
        SubtractDrift(varargin{1});
    case 'DeleteQueue'
        DeleteQueue(varargin{1});
    case 'ExportMeasure'
        ExportMeasure(varargin{1});        
    case 'ExportScan'
        ExportScan(varargin{1});           
    case 'ExportKymo'
        ExportKymo(varargin{1});          
    case 'RefreshServerQueue'
        RefreshServerQueue(varargin{1});
    case 'CheckDrift'
        CheckDrift(varargin{1});      
    case 'CorrectKymoIndex'
        CorrectKymoIndex(varargin{1});      
    case 'IgnoreObjects'   
        IgnoreObjects(varargin{1},varargin{2});
    case 'RenameObject'   
        RenameObject(varargin{1},varargin{2});        
    case 'LoadQueue'   
        LoadQueue(varargin{1});        
    case 'SaveQueue'   
        SaveQueue;                
    case 'UpdateKymoTracks'   
        UpdateKymoTracks(varargin{1});                        
    case 'CheckConfig'   
        CheckConfig;                 
end

function CheckConfig
fConfigGui('Create');
fShared('ReturnFocus');

function ExportKymo(hMainGui)
mode=get(gcbo,'String');
if strcmp(mode,'Export')==1
    [FileName, PathName] = uiputfile({'*.tif','TIFF-File (*.tif)'},'Save FIESTA Kymograph',fShared('GetSaveDir'));    
    if FileName~=0
        fShared('SetSaveDir',PathName);
        file = [PathName FileName];    
        if isempty(findstr('.tif',file))
            file = [file '.tif'];
        end           
        Image=hMainGui.KymoImage;
        min_x = min(Image,[],1);
        min_y = min(Image,[],2);        
        Image(min_y==2^16,:)=[];
        Image(:,min_x==2^16)=[];  
        Image=(double(Image)-hMainGui.Values.ScaleMin)/(hMainGui.Values.ScaleMax-hMainGui.Values.ScaleMin);
        Image(Image<0)=0;
        Image(Image>1)=1;
        Image=Image*255;
        imwrite(uint8(Image),file,'Compression','none');        
    end
end
fShared('ReturnFocus');

function ExportScan(hMainGui)
global Stack;
global Config;
mode=get(gcbo,'String');
FilterIndex=0;
if strcmp(mode,'Export')==1
    [FileName, PathName, FilterIndex] = uiputfile({'*.jpg','JPG-File (*.jpg)';'*.txt','TXT-File (*.txt)'},fShared('GetSaveDir'));
    if PathName~=0
        fShared('SetSaveDir',PathName);
    end
end
if FilterIndex>0||strcmp(mode,'Print')==1
    set(hMainGui.fig,'Pointer','watch');   
    if FilterIndex==1
        if size(findstr('.jpg',FileName))==0
            file=sprintf('%s/%s.jpg',PathName,FileName);
        else
            file=sprintf('%s/%s',PathName,FileName);
        end
    end
    if FilterIndex==2
        if size(findstr('.txt',FileName))==0
            file=sprintf('%s/%s.txt',PathName,FileName);
        else
            file=sprintf('%s/%s',PathName,FileName);
        end
    end
    if hMainGui.Values.FrameIdx<1
        f=round(get(hMainGui.MidPanel.sFrame,'Value'));
    else
        f=hMainGui.Values.FrameIdx;
    end
    Z = interp2(double(Stack{f}),hMainGui.Scan.InterpX,hMainGui.Scan.InterpY);
    I = mean(Z,1);
    D = hMainGui.Scan.InterpD;
    if FilterIndex==1||strcmp(mode,'Print')==1
        h=figure('PaperUnits','centimeter','Visible','off','PaperType','A4','PaperPositionMode','manual','PaperPosition',[0 0 29.7 21]);
        plot(D,I,'b-');
        xlabel('Intensity vs. Distance in um');
        if FilterIndex==1
            print(h,file,'-djpeg','-r600');
        else
            set(h,'PaperOrientation','landscape');
            print(h,'-v');
        end
        close(h);
    elseif FilterIndex==2
        fh=fopen(file,'w');
        fprintf(fh,'%s - Frame: %d\n',Config.StackName,f);
        fprintf(fh,'Distance[um]\tIntensity[counts]\n');
        for j=1:length(D)
            fprintf(fh,'%f\t%f\n',D(j),I(j));
        end
        fclose(fh);
    end
    setappdata(0,'hMainGui',hMainGui);
    set(hMainGui.fig,'Pointer','arrow');       
end        
fShared('ReturnFocus');

function ExportMeasure(hMainGui)
[FileName, PathName] = uiputfile({'*.txt','TXT-File (*.txt)'},'Save FIESTA Measurements',fShared('GetSaveDir'));
if FileName~=0
    fShared('SetSaveDir',PathName);
    file = [PathName FileName];    
    if isempty(findstr('.txt',file))
        file = [file '.txt'];
    end       
    str{1}='';
    if get(hMainGui.RightPanel.pTools.cLengthArea,'Value')==1
        str{1}=sprintf('%sLength/Area [µm/µm²]\t',str{1});
    end
    if get(hMainGui.RightPanel.pTools.cIntegral,'Value')==1
        str{1}=sprintf('%sIntegral\t',str{1});
    end
    if get(hMainGui.RightPanel.pTools.cMean,'Value')==1
        str{1}=sprintf('%sMean\t',str{1});
    end
    if get(hMainGui.RightPanel.pTools.cSTD,'Value')==1
        str{1}=sprintf('%sSTD\t',str{1});
    end
    for i=1:length(hMainGui.Measure)
        str{i+1}=''; %#ok<AGROW>
        if get(hMainGui.RightPanel.pTools.cLengthArea,'Value')==1
            str{i+1}=sprintf('%s%f\t',str{i+1},hMainGui.Measure(i).LenArea); %#ok<AGROW>
        end
        if get(hMainGui.RightPanel.pTools.cIntegral,'Value')==1
            if hMainGui.Measure(i).Dim==1
                str{i+1}=sprintf('%s%f\t',str{i+1},hMainGui.Measure(i).Integral); %#ok<AGROW>
            else
                str{i+1}=sprintf('%s%f\t',str{i+1},hMainGui.Measure(i).Integral); %#ok<AGROW>
            end
        end
        if get(hMainGui.RightPanel.pTools.cMean,'Value')==1
            str{i+1}=sprintf('%s%f\t',str{i+1},hMainGui.Measure(i).Mean); %#ok<AGROW>
        end
        if get(hMainGui.RightPanel.pTools.cSTD,'Value')==1
             str{i+1}=sprintf('%s%f\t',str{i+1},hMainGui.Measure(i).STD);%#ok<AGROW>
        end
    end
    f=fopen(file,'w');
    for i=1:length(str)
        fprintf(f,'%s\n',str{i});
    end
    fclose(f);
end
fShared('ReturnFocus');

function Object=CalcDrift(Object,Drift,Value)
if Value == 1 && Object.Drift == 0
    t = -1; %subtract drift
elseif Value == 0 && Object.Drift == 1
    t = 1; %add drift
else
    return;
end
nData = size(Object.Results,1);    
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
Object.Drift=Value;

function SubtractDrift(hMainGui)
global Molecule;
global Filament;
Drift=getappdata(hMainGui.fig,'Drift');
if ~isempty(Drift)
    fDataGui('DeleteGUI',1);
    Value=get(gcbo,'Value');
    set(hMainGui.RightPanel.pData.cMolDrift,'Value',Value);
    set(hMainGui.RightPanel.pData.cFilDrift,'Value',Value);    
    nMol=length(Molecule);
    nFil=length(Filament);
    for i=1:nMol
        Molecule(i)=CalcDrift(Molecule(i),Drift,Value);
    end
    for i=1:nFil
        Filament(i)=CalcDrift(Filament(i),Drift,Value);
    end
    fShow('Marker',hMainGui,hMainGui.Values.FrameIdx);
    fShow('Tracks');
else
    set(hMainGui.RightPanel.pData.cMolDrift,'Value',0);
    set(hMainGui.RightPanel.pData.cFilDrift,'Value',0);    
end
fShared('ReturnFocus');

function CheckDrift(hMainGui)
Drift=getappdata(hMainGui.fig,'Drift');
if ~isempty(Drift)
    set(hMainGui.RightPanel.pData.cMolDrift,'Value',0);   
    set(hMainGui.RightPanel.pData.cFilDrift,'Value',0); 
    fShow('Marker',hMainGui,hMainGui.Values.FrameIdx);
    fShow('Tracks');    
end
fShared('ReturnFocus');

function ShowAllFil(hMainGui)
if strcmp(get(gcbo,'Tag'),'cShowAllFil')
   if get(gcbo,'Value')
       set(hMainGui.RightPanel.pData.cShowWholeFil,'Enable','on');
   else
       set(hMainGui.RightPanel.pData.cShowWholeFil,'Enable','off');
   end
end
fShared('ReturnFocus');
fShow('Image');

function ListButton(hMainGui,type)
global Molecule;
global Filament;
fShared('BackUp',hMainGui);
if strcmp(type,'Molecule')
    Object=Molecule;
else
    Object=Filament;
end
nObj=length(Object);
idx=get(gcbo,'UserData');
if strcmp(type,'Molecule')==1
    value=round(get(hMainGui.RightPanel.pData.sMolList,'Value'));
else
    value=round(get(hMainGui.RightPanel.pData.sFilList,'Value'));
end
if nObj>8
    fDataGui('Create',type,nObj-7-value+idx);
else
    fDataGui('Create',type,idx);
end


function QueueCheck(hMainGui)
global Queue;
nQue=length(Queue);
idx=get(gcbo,'UserData');
value=round(get(hMainGui.RightPanel.pQueue.sLocList,'Value'));
if nQue>8
    Queue(nQue-7-value+idx).Check=get(gcbo,'Value');
else
    Queue(idx).Check=get(gcbo,'Value');
end
fShared('ReturnFocus');

function ListVisible(hMainGui,Mode)
global Molecule;
global Filament;
global KymoTrackMol;
global KymoTrackFil;
idx=get(gcbo,'UserData');
if strcmp(Mode,'Molecule')
    Molecule=fShared('VisibleOne',Molecule,KymoTrackMol,hMainGui.RightPanel.pData.MolList,idx*1i,[],hMainGui.RightPanel.pData.sMolList);
else
    Filament=fShared('VisibleOne',Filament,KymoTrackFil,hMainGui.RightPanel.pData.FilList,idx*1i,[],hMainGui.RightPanel.pData.sFilList);
end
fShared('ReturnFocus');
fShow('Marker',hMainGui,hMainGui.Values.FrameIdx);

function ListSlider(hMainGui)
global Molecule;
global Filament;
UpdateList(hMainGui.RightPanel.pData.MolList,Molecule,hMainGui.RightPanel.pData.sMolList,hMainGui.Menu.ctListMol);
UpdateList(hMainGui.RightPanel.pData.FilList,Filament,hMainGui.RightPanel.pData.sFilList,hMainGui.Menu.ctListFil);
fShared('ReturnFocus');

function ShowKymoGraph(hMainGui)
if get(hMainGui.RightPanel.pTools.cShowKymoGraph,'Value')==1
    NewKymoGraph(hMainGui);
else
    set(hMainGui.RightPanel.pTools.cShowKymoGraph,'Value',1);
end
fShared('ReturnFocus');

function IgnoreObjects(hMainGui,Mode)
global Molecule;
global Filament;
global KymoTrackMol;
global KymoTrackFil;
Value=get(gcbo,'Value');
if strcmp(Mode,'Molecule')
    Object=Molecule;
    KymoObject=KymoTrackMol;
else
    Object=Filament;
    KymoObject=KymoTrackFil;
end
for n=1:length(Object)
    Object(n).Selected=-Value;
    visible='off';
    if Object(n).Selected==0&&Object(n).Visible==1
        visible='on';
    end
    set(Object(n).PlotHandles(1),'Visible',visible);
    set(Object(n).PlotHandles(2:3),'Visible','off');
    k=find([KymoObject.Index]==n);
    if ~isempty(k)
        set(KymoObject(k).PlotHandles(1),'Visible',visible);            
        set(KymoObject(k).PlotHandles(2:3),'Visible','off');        
    end  
end
if strcmp(Mode,'Molecule')
    Molecule=Object;
else
    Filament=Object;
end
UpdateList(hMainGui.RightPanel.pData.MolList,Molecule,hMainGui.RightPanel.pData.sMolList,hMainGui.Menu.ctListMol);
UpdateList(hMainGui.RightPanel.pData.FilList,Filament,hMainGui.RightPanel.pData.sFilList,hMainGui.Menu.ctListFil);
fShow('Marker',hMainGui,hMainGui.Values.FrameIdx);
fShared('ReturnFocus');

function KymoFrames(hMainGui)
global Stack;
s=str2double(get(hMainGui.RightPanel.pTools.eKymoStart,'String'));
e=str2double(get(hMainGui.RightPanel.pTools.eKymoEnd,'String'));
if strcmp(get(gcbo,'UserData'),'Start')
    s=min([s e-1]);
    s=max([s 1]);
    e=max([e s+1]);
else    
    e=min([e length(Stack)]);
 	e=max([e s+1]);
end    
set(hMainGui.RightPanel.pTools.eKymoStart,'String',num2str(s));
set(hMainGui.RightPanel.pTools.eKymoEnd,'String',num2str(e));
if get(hMainGui.RightPanel.pTools.cShowKymoGraph,'Value')==1
    NewKymoGraph(hMainGui);
end
fShared('ReturnFocus');

function ScanSize(hMainGui)
value=round(str2double(get(hMainGui.RightPanel.pTools.eScanSize,'String')));
if value<1
    value=1;
end
if ~isnan(value)
   if value>10
       value=10;
   end
   hMainGui.Values.ScanSize=value;
   setappdata(0,'hMainGui',hMainGui);
   NewScan(hMainGui);
   if get(hMainGui.RightPanel.pTools.cShowKymoGraph,'Value')==1
       hMainGui=getappdata(0,'hMainGui');
       NewKymoGraph(hMainGui);
   end
end
set(hMainGui.RightPanel.pTools.eScanSize,'String',num2str(value));
fShared('ReturnFocus');

function MeasureTable(hMainGui)
idx=get(hMainGui.RightPanel.pTools.lMeasureTable,'Value');
set(hMainGui.RightPanel.pTools.lMeasureTable,'UserData',idx-1);
setappdata(0,'hMainGui',hMainGui);
fShared('ReturnFocus');

function str=formatstr(width,format,value)
str=sprintf(format,value);
str = strrep(str, 'e+00', 'e+');
l=width-length(str);
for i=0.5:0.5:l
    str=[' ' str]; %#ok<AGROW>
end

function UpdateLineScan(hMainGui)
global Stack
if hMainGui.Values.FrameIdx<1
    f=round(get(hMainGui.MidPanel.sFrame,'Value'));
else
    f=hMainGui.Values.FrameIdx;
end
Z = interp2(double(Stack{f}),hMainGui.Scan.InterpX,hMainGui.Scan.InterpY);
I = mean(Z,1);
set(0,'CurrentFigure',hMainGui.fig);
set(hMainGui.fig,'CurrentAxes',hMainGui.RightPanel.pTools.aLineScan);
set(hMainGui.RightPanel.pTools.aLineScan,'Visible','on');
delete(findobj('Tag','plotLineScan'));
line(hMainGui.Scan.InterpD,I,'Color','blue','LineStyle','-','UIContextMenu',hMainGui.Menu.ctScan,'Tag','plotLineScan');
XTick=get(hMainGui.RightPanel.pTools.aLineScan,'XTick');
XTickLabel=cell(1,length(XTick));
for k=1:length(XTick)-1
    XTickLabel{k}=num2str(XTick(k));
end
XTickLabel{k+1}='[um]';
format_ticks(hMainGui.RightPanel.pTools.aLineScan,XTickLabel);
setappdata(0,'hMainGui',hMainGui);

function NewKymoGraph(hMainGui)
global Stack;
global Molecule;
global Filament;
global KymoTrackMol;
global KymoTrackFil;
s=str2double(get(hMainGui.RightPanel.pTools.eKymoStart,'String'));
e=str2double(get(hMainGui.RightPanel.pTools.eKymoEnd,'String'));
if ~isnan(s)&&~isnan(e)&&length(Stack)>1
    scan_length=size(hMainGui.Scan.InterpX,2);
    KymoGraph=zeros(e-s+1,scan_length);
    workbar(0,'Calculating KymoGraph','Progres',-1);             
    for i=s:e
        Z = interp2(double(Stack{i}),hMainGui.Scan.InterpX,hMainGui.Scan.InterpY);
        KymoGraph(i-s+1,:)=mean(Z,1);
        if i>s
            h = findobj('Tag','timebar');
            if isempty(h)
                return
            end
        end
        workbar((i-s)/(e-s),'Calculating KymoGraph','Progres',-1);             
    end
    delete(hMainGui.RightPanel.pTools.aKymoGraph);
    hMainGui.RightPanel.pTools.aKymoGraph = axes('Parent',hMainGui.RightPanel.pTools.pKymoGraph,'Units','normalized','UIContextMenu',hMainGui.Menu.ctKymoGraph,'Position',[0 0 1 1],'Tag','aKymoGraph','NextPlot','add','Visible','off');  
    [y,x]=size(KymoGraph);
    if y/x >= hMainGui.ZoomKymo.aspect
        borders = ((y/hMainGui.ZoomKymo.aspect)-x)/2;
        hMainGui.ZoomKymo.globalXY = {[0.5-borders x+0.5+borders],[0.5 y+0.5]};
    else
        borders = ((x*hMainGui.ZoomKymo.aspect)-y)/2;
        hMainGui.ZoomKymo.globalXY = {[0.5 x+0.5],[0.5-borders y+0.5+borders]};
    end
    hMainGui.KymoImage=KymoGraph;
    Image=(hMainGui.KymoImage-hMainGui.Values.ScaleMin)/(hMainGui.Values.ScaleMax-hMainGui.Values.ScaleMin);
    Image(Image<0)=0;
    Image(Image>1)=1;
    Image=Image*2^16;
    hMainGui.KymoGraph=image(Image,'Parent',hMainGui.RightPanel.pTools.aKymoGraph,'CDataMapping','scaled');
    set(hMainGui.RightPanel.pTools.aKymoGraph,'CLim',[0 65535],'YDir','reverse'); 
    set(hMainGui.RightPanel.pTools.pKymoGraph,'Visible','on'); 
    set(hMainGui.fig,'colormap',colormap('Gray'));
    set(hMainGui.KymoGraph,'Tag','plotScan');
    if ~isempty(Molecule)
        [hMainGui,KymoTrackMol]=ShowTracksKymo(hMainGui,Molecule,hMainGui.Scan.InterpX,hMainGui.Scan.InterpY,s,e,hMainGui.Scan.lx,hMainGui.Scan.ux,hMainGui.Scan.ly,hMainGui.Scan.uy);
    end
    if ~isempty(Filament)
        [hMainGui,KymoTrackFil]=ShowTracksKymo(hMainGui,Filament,hMainGui.Scan.InterpX,hMainGui.Scan.InterpY,s,e,hMainGui.Scan.lx,hMainGui.Scan.ux,hMainGui.Scan.ly,hMainGui.Scan.uy);
    end
    set(hMainGui.RightPanel.pTools.aKymoGraph,{'xlim','ylim'},hMainGui.ZoomKymo.globalXY,'Visible','off'); 
    hMainGui.ZoomKymo.currentXY=hMainGui.ZoomKymo.globalXY;
    hMainGui.ZoomKymo.level=0;
    setappdata(0,'hMainGui',hMainGui);
end

function UpdateKymoTracks(hMainGui)
global Molecule;
global Filament;
global KymoTrackMol;
global KymoTrackFil;
s=str2double(get(hMainGui.RightPanel.pTools.eKymoStart,'String'));
e=str2double(get(hMainGui.RightPanel.pTools.eKymoEnd,'String'));
if ~isempty(hMainGui.KymoImage)
    if ~isempty(Molecule)
        h = [KymoTrackMol.PlotHandles];
        delete(h(ishandle(h)));
        [hMainGui,KymoTrackMol]=ShowTracksKymo(hMainGui,Molecule,hMainGui.Scan.InterpX,hMainGui.Scan.InterpY,s,e,hMainGui.Scan.lx,hMainGui.Scan.ux,hMainGui.Scan.ly,hMainGui.Scan.uy);
    end
    if ~isempty(Filament)
        h = [KymoTrackFil.PlotHandles];
        delete(h(ishandle(h)));
        [hMainGui,KymoTrackFil]=ShowTracksKymo(hMainGui,Filament,hMainGui.Scan.InterpX,hMainGui.Scan.InterpY,s,e,hMainGui.Scan.lx,hMainGui.Scan.ux,hMainGui.Scan.ly,hMainGui.Scan.uy);
    end
end
setappdata(0,'hMainGui',hMainGui);

function NewScan(hMainGui)
set(0,'CurrentFigure',hMainGui.fig);
set(hMainGui.fig,'CurrentAxes',hMainGui.MidPanel.aView);
for i=1:length(hMainGui.Scan.X)
    if i==1   
        v=[hMainGui.Scan.X(i+1)-hMainGui.Scan.X(i) hMainGui.Scan.Y(i+1)-hMainGui.Scan.Y(i) 0];
        n(i,:)=[v(2) -v(1) 0]/norm(v); %#ok<AGROW>
    elseif i==length(hMainGui.Scan.X)
        v=[hMainGui.Scan.X(i)-hMainGui.Scan.X(i-1) hMainGui.Scan.Y(i)-hMainGui.Scan.Y(i-1) 0];
        n(i,:)=[v(2) -v(1) 0]/norm(v); %#ok<AGROW>
    else
        v1=[hMainGui.Scan.X(i+1)-hMainGui.Scan.X(i) hMainGui.Scan.Y(i+1)-hMainGui.Scan.Y(i) 0];
        v2=-[hMainGui.Scan.X(i)-hMainGui.Scan.X(i-1) hMainGui.Scan.Y(i)-hMainGui.Scan.Y(i-1) 0];
        n(i,:)=v1/norm(v1)+v2/norm(v2); %#ok<AGROW>
        if norm(n(i,:))==0
            n(i,:)=[v1(2) -v1(1) 0]/norm(v1);
        else
            n(i,:)=n(i,:)/norm(n(i,:)); %#ok<AGROW>
        end
        z=cross(v1,n(i,:));
        if z(3)>0
            n(i,:)=-n(i,:); %#ok<AGROW>
        end
    end
    lx(i)=hMainGui.Scan.X(i)+hMainGui.Values.ScanSize*n(i,1); %#ok<AGROW>
    ux(i)=hMainGui.Scan.X(i)-hMainGui.Values.ScanSize*n(i,1); %#ok<AGROW>
    ly(i)=hMainGui.Scan.Y(i)+hMainGui.Values.ScanSize*n(i,2); %#ok<AGROW>
    uy(i)=hMainGui.Scan.Y(i)-hMainGui.Values.ScanSize*n(i,2); %#ok<AGROW>
end
delete(findobj('Tag','plotScan'));
line(hMainGui.Scan.X,hMainGui.Scan.Y,'Color','red','LineStyle','-.','Tag','plotScan','UIContextMenu',hMainGui.Menu.ctScan);
line(lx,ly,'Color','red','LineStyle',':','Tag','plotScan','UIContextMenu',hMainGui.Menu.ctScan);
line(ux,uy,'Color','red','LineStyle',':','Tag','plotScan','UIContextMenu',hMainGui.Menu.ctScan);
l=0;
nXI=linspace(hMainGui.Scan.X(1)+hMainGui.Values.ScanSize*n(1,1),hMainGui.Scan.X(1)-hMainGui.Values.ScanSize*n(1,1),2*hMainGui.Values.ScanSize);
nYI=linspace(hMainGui.Scan.Y(1)+hMainGui.Values.ScanSize*n(1,2),hMainGui.Scan.Y(1)-hMainGui.Values.ScanSize*n(1,2),2*hMainGui.Values.ScanSize);
d(1)=0;
p=2;
X=nXI';
Y=nYI';
for i=1:length(hMainGui.Scan.X)-1
    l=l+norm([hMainGui.Scan.X(i+1)-hMainGui.Scan.X(i) hMainGui.Scan.Y(i+1)-hMainGui.Scan.Y(i)]);
    if l>1
        XI=linspace(hMainGui.Scan.X(i),hMainGui.Scan.X(i+1),ceil(l));
        YI=linspace(hMainGui.Scan.Y(i),hMainGui.Scan.Y(i+1),ceil(l));
        for j=2:length(XI)
            nn(1)=(j-1)*n(i+1,1)+(length(XI)-j)*n(i,1);
            nn(2)=(j-1)*n(i+1,2)+(length(XI)-j)*n(i,2);
            nn=nn/norm(nn);
            nXI=linspace(XI(j)+hMainGui.Values.ScanSize*nn(1),XI(j)-hMainGui.Values.ScanSize*nn(1),2*hMainGui.Values.ScanSize);
            nYI=linspace(YI(j)+hMainGui.Values.ScanSize*nn(2),YI(j)-hMainGui.Values.ScanSize*nn(2),2*hMainGui.Values.ScanSize);
            X(:,p)=nXI';
            Y(:,p)=nYI';
            d(p)=d(p-1)+norm([XI(j)-XI(j-1) YI(j)-YI(j-1)])*hMainGui.Values.PixSize/1000; %#ok<AGROW>
            p=p+1;
       end
       l=0;
    end
end
hMainGui.Scan.InterpX=X;
hMainGui.Scan.InterpY=Y;
hMainGui.Scan.lx=lx;
hMainGui.Scan.ux=ux;
hMainGui.Scan.ly=ly;
hMainGui.Scan.uy=uy;
hMainGui.Scan.InterpD=d;
hMainGui.CursorMode='Normal';
set(hMainGui.RightPanel.pTools.cShowKymoGraph,'Enable','on'); 
set(hMainGui.RightPanel.pTools.tKymoStart,'Enable','on');     
set(hMainGui.RightPanel.pTools.eKymoStart,'Enable','on');                                             
set(hMainGui.RightPanel.pTools.tKymoEnd,'Enable','on');                                                                                  
set(hMainGui.RightPanel.pTools.eKymoEnd,'Enable','on');   
setappdata(0,'hMainGui',hMainGui);
UpdateLineScan(hMainGui);
AllToolsOff(hMainGui);
fToolBar('Cursor',hMainGui);

function DeleteScan(hMainGui)
global KymoTrackMol;
global KymoTrackFil;
plotScan=findobj('Tag','plotScan');
if ~isempty(plotScan)
    hMainGui.Values.CursorDownPos(:)=0;
    h = [KymoTrackMol.PlotHandles KymoTrackFil.PlotHandles];
    delete(h(ishandle(h)));
    KymoTrackMol(:)=[];
    KymoTrackFil(:)=[];
    delete(plotScan);
    delete(findobj('Tag','plotLineScan'));
    cla(hMainGui.RightPanel.pTools.aLineScan,'reset');
    hMainGui.KymoGraph=[];
    hMainGui.KymoImage=[];
    hMainGui.Scan=[];
end
setappdata(0,'hMainGui',hMainGui);

function [hMainGui,KymoTrackObj]=ShowTracksKymo(hMainGui,Objects,X,Y,s,e,lx,ux,ly,uy)
set(0,'CurrentFigure',hMainGui.fig);
set(hMainGui.fig,'CurrentAxes',hMainGui.RightPanel.pTools.aKymoGraph);
KymoTrackObj=struct('Index',{},'Track',{},'PlotHandles',{});
nTrack=1;
newX=mean(X,1);
newY=mean(Y,1);
for idx=1:length(Objects)
    polyX=[lx ux(length(ux):-1:1)];
    polyY=[ly uy(length(uy):-1:1)];    
    OX=Objects(idx).Results(:,3)/hMainGui.Values.PixSize;
    OY=Objects(idx).Results(:,4)/hMainGui.Values.PixSize;
    IN=find(inpolygon(OX,OY,polyX,polyY)==1);
    k=find(Objects(idx).Results(IN,1)>=s&Objects(idx).Results(IN,1)<=e);
    KymoTrack=[];
    for n=1:length(k)
        [~,t]=min(sqrt( (newX-OX(IN(k(n)))).^2 + (newY-OY(IN(k(n)))).^2));
        KymoTrack(n,:)=[Objects(idx).Results(IN(k(n)),1)-s t]; %#ok<AGROW>
    end
    if ~isempty(KymoTrack)
        KymoTrackObj(nTrack).Name=Objects(idx).Name;
        KymoTrackObj(nTrack).Index=idx;        
        KymoTrackObj(nTrack).Track=KymoTrack;        
        KymoTrackObj(nTrack).PlotHandles(1,1) = line(KymoTrack(:,2),KymoTrack(:,1),'Color',Objects(idx).Color,'Visible','off');
        KymoTrackObj(nTrack).PlotHandles(2,1) = line(KymoTrack(:,2),KymoTrack(:,1),'Color','black','Visible','off','LineStyle','-.');        
        KymoTrackObj(nTrack).PlotHandles(3,1) = line(KymoTrack(:,2),KymoTrack(:,1),'Color','white','Visible','off','LineStyle',':');
        if Objects(idx).Visible
            set(KymoTrackObj(nTrack).PlotHandles(1,1),'Visible','on');
        end
        if Objects(idx).Selected
            set(KymoTrackObj(nTrack).PlotHandles(2:3,1),'Visible','on');
        end
        nTrack=nTrack+1;
    end
end

function CorrectKymoIndex(mode)
global Molecule;
global Filament;
global KymoTrackMol;
global KymoTrackFil;
if strcmp(mode,'Molecule')
    Objects=Molecule;
    KymoTrack=KymoTrackMol;
else
    Objects=Filament;
    KymoTrack=KymoTrackFil;
end
Names=cell(1,length(Objects));
for n=1:length(Objects)
    Names{n}=Objects(n).Name;
end    
for n=1:length(KymoTrack)
    KymoTrack(n).Index=strmatch(KymoTrack(n).Name, Names);    
end
if strcmp(mode,'Molecule')
    Molecule=Objects;
    KymoTrackMol=KymoTrack;
else
    Filament=Objects;
    KymoTrackFil=KymoTrack;
end
    

function UpdateMeasure(hMainGui)
str{1}='';
sprintf('Length/Area   Integral  Mean  STD');
if get(hMainGui.RightPanel.pTools.cLengthArea,'Value')==1
     str{1}=[str{1} 'Length/Area   '];
end
if get(hMainGui.RightPanel.pTools.cIntegral,'Value')==1
    str{1}=[str{1} 'Integral     '];
end
if get(hMainGui.RightPanel.pTools.cMean,'Value')==1
    str{1}=[str{1} '    Mean     '];
end
if get(hMainGui.RightPanel.pTools.cSTD,'Value')==1
    str{1}=[str{1} '     STD'];
end
for i=1:length(hMainGui.Measure)
     str{i+1}=''; %#ok<AGROW>
     if get(hMainGui.RightPanel.pTools.cLengthArea,'Value')==1
         str{i+1}=[str{i+1} formatstr(7,'%.3f',hMainGui.Measure(i).LenArea)]; %#ok<AGROW>
         if hMainGui.Measure(i).Dim==1
             str{i+1}=[str{i+1} 'µm     ']; %#ok<AGROW>
         else
             str{i+1}=[str{i+1} 'µm²    ']; %#ok<AGROW>
          end
     end
     if get(hMainGui.RightPanel.pTools.cIntegral,'Value')==1
         if hMainGui.Measure(i).Dim==1
             str{i+1}=[str{i+1} formatstr(7,'%.0f',hMainGui.Measure(i).Integral) '     ']; %#ok<AGROW>
         else
             str{i+1}=[str{i+1} formatstr(7.5,'%.2e',hMainGui.Measure(i).Integral) '     ']; %#ok<AGROW>
         end
     end
     if get(hMainGui.RightPanel.pTools.cMean,'Value')==1
         str{i+1}=[str{i+1} formatstr(7,'%.1f',hMainGui.Measure(i).Mean) '     ']; %#ok<AGROW>
     end
     if get(hMainGui.RightPanel.pTools.cSTD,'Value')==1
         str{i+1}=[str{i+1} formatstr(7,'%.2f',hMainGui.Measure(i).STD) '     ']; %#ok<AGROW>
     end
end
if isempty(hMainGui.Measure)
    set(hMainGui.RightPanel.pTools.lMeasureTable,'String','','UIContextMenu','','Value',1);
else
    set(hMainGui.RightPanel.pTools.lMeasureTable,'String',str,'UIContextMenu',hMainGui.Menu.ctMeasure,'Value',length(str));
end
set(hMainGui.fig,'pointer','arrow');
setappdata(0,'hMainGui',hMainGui);


function SetAllPanelsOff(hMainGui)
set(hMainGui.RightPanel.pData.panel,'Visible','off');
set(hMainGui.RightPanel.pTools.panel,'Visible','off');
set(hMainGui.RightPanel.pQueue.panel,'Visible','off');

function DataPanel(hMainGui)
SetAllPanelsOff(hMainGui);
set(hMainGui.RightPanel.pData.panel,'Visible','on');

function ToolsPanel(hMainGui)
SetAllPanelsOff(hMainGui);
set(hMainGui.RightPanel.pTools.panel,'Visible','on');

function QueuePanel(hMainGui)
SetAllPanelsOff(hMainGui);
set(hMainGui.RightPanel.pQueue.panel,'Visible','on');

function DataMoleculesPanel(hMainGui)
SetAllPanelsOff(hMainGui);
set(hMainGui.RightPanel.pData.panel,'Visible','on');
set(hMainGui.RightPanel.pData.pMoleculesPan,'Visible','on');
set(hMainGui.RightPanel.pData.pFilamentsPan,'Visible','off');

function DataFilamentsPanel(hMainGui)
SetAllPanelsOff(hMainGui);
set(hMainGui.RightPanel.pData.panel,'Visible','on');
set(hMainGui.RightPanel.pData.pMoleculesPan,'Visible','off');
set(hMainGui.RightPanel.pData.pFilamentsPan,'Visible','on');

function ToolsMeasurePanel(hMainGui)
SetAllPanelsOff(hMainGui);
set(hMainGui.RightPanel.pTools.panel,'Visible','on');
set(hMainGui.RightPanel.pTools.pMeasurePan,'Visible','on');
set(hMainGui.RightPanel.pTools.pScanPan,'Visible','off');

function ToolsScanPanel(hMainGui)
SetAllPanelsOff(hMainGui);
set(hMainGui.RightPanel.pTools.panel,'Visible','on');
set(hMainGui.RightPanel.pTools.pMeasurePan,'Visible','off');
set(hMainGui.RightPanel.pTools.pScanPan,'Visible','on');

function QueueServerPanel(hMainGui)
SetAllPanelsOff(hMainGui);
set(hMainGui.RightPanel.pQueue.panel,'Visible','on');
set(hMainGui.RightPanel.pQueue.pServerPan,'Visible','on');
set(hMainGui.RightPanel.pQueue.pLocalPan,'Visible','off');

function QueueLocalPanel(hMainGui)
SetAllPanelsOff(hMainGui);
set(hMainGui.RightPanel.pQueue.panel,'Visible','on');
set(hMainGui.RightPanel.pQueue.pServerPan,'Visible','off');
set(hMainGui.RightPanel.pQueue.pLocalPan,'Visible','on');

function AllToolsOff(hMainGui)
set(hMainGui.RightPanel.pTools.bLine,'Value',0);
set(hMainGui.RightPanel.pTools.bSegLine,'Value',0);
set(hMainGui.RightPanel.pTools.bFreehand,'Value',0);
set(hMainGui.RightPanel.pTools.bRectangle,'Value',0);
set(hMainGui.RightPanel.pTools.bEllipse,'Value',0);
set(hMainGui.RightPanel.pTools.bPolygon,'Value',0);
set(hMainGui.RightPanel.pTools.bLineScan,'Value',0);
set(hMainGui.RightPanel.pTools.bSegLineScan,'Value',0);
set(hMainGui.RightPanel.pTools.bFreehandScan,'Value',0);
if isfield(hMainGui,'Plots')
    if isfield(hMainGui.Plots,'Measure')
        nMeasure=length(hMainGui.Plots.Measure);
        if nMeasure>0
            color=get(hMainGui.Plots.Measure(nMeasure),'Color');    
            if sum(color)==3
                hMainGui.Values.CursorDownPos(:)=0; 
                delete(hMainGui.Plots.Measure(nMeasure));    
                hMainGui.Measure(nMeasure)=[];
                hMainGui.Plots.Measure(nMeasure)=[];
            end
        end
    end
    if isfield(hMainGui,'Region')
        nRegion=length(hMainGui.Region);
        if nRegion>0
            color=get(hMainGui.Plots.Region(nRegion),'Color');    
            if sum(color)==3
                hMainGui.Values.CursorDownPos(:)=0; 
                delete(hMainGui.Plots.Region(nRegion));
                hMainGui.Region(nRegion)=[];
                hMainGui.Plots.Region(nRegion)=[];
            end
        end
    end
end
plotScan=findobj('Tag','plotScan');
if ~isempty(plotScan)
    color=get(plotScan(1),'Color');    
    if sum(color)==3
        hMainGui.Values.CursorDownPos(:)=0;
        delete(plotScan);    
        hMainGui.Scan=[];
    end
end
setappdata(0,'hMainGui',hMainGui);

function ToggleTool(hMainGui)
value=get(gcbo,'Value');
fToolBar('Cursor',hMainGui);
hMainGui=getappdata(0,'hMainGui');
set(gcbo,'Value',value);
if value==1
    hMainGui.CursorMode=get(gcbo,'UserData');
else
    hMainGui.CursorMode='Normal';
end
hMainGui.Values.CursorDownPos(:)=0;
setappdata(0,'hMainGui',hMainGui);

function UpdateList(hList,List,slider,UIContext)
l=length(List);
if l>8
    slider_step(1) = 1/(l-8);
    slider_step(2) = 8/(l-8);
    if strcmp(get(slider,'Enable'),'on')==1
        v=get(slider,'Value');
        if v>l-7
            v=l-7;
        end
        set(slider,'sliderstep',slider_step,...
         'max',l-7,'min',1,'Value',v)
    else
        set(slider,'sliderstep',slider_step,...
         'max',l-7,'min',1,'Value',l-7,'Enable','on')
    end
    ListBegin=(l-7)-round(get(slider,'Value'));
    ListLength=8;
else
    slider_step(1) = 0.1;
    slider_step(2) = 0.1;
    set(slider,'sliderstep',slider_step,...
         'max',1,'min',0,'Value',1,'Enable','off')
     ListLength=l;
     ListBegin=0;
end
CDataVisible(:,:,1)=[NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.964705882352941,0.886274509803922,0.811764705882353,0.721568627450980,0.650980392156863,0.635294117647059,0.721568627450980,0.862745098039216,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.858823529411765,0.596078431372549,0.462745098039216,0.356862745098039,0.262745098039216,0.196078431372549,0.176470588235294,0.262745098039216,0.431372549019608,0.709803921568628,NaN,NaN,NaN;NaN,NaN,NaN,NaN,0.992156862745098,0.600000000000000,0.168627450980392,0,0,0,0,0,0,0,0,0,0,0.258823529411765,0.905882352941177,NaN;NaN,NaN,NaN,0.843137254901961,0.227450980392157,0,0,0,0,0,0,0,0,0,0,0,0,0,0.372549019607843,NaN;NaN,NaN,0.729411764705882,0.0509803921568627,0,0,0,0,0,0,0,0,0.0274509803921569,0.211764705882353,0.00392156862745098,0,0,0.0745098039215686,0.874509803921569,NaN;NaN,0.650980392156863,0,0,0,0,0.0392156862745098,0.168627450980392,0,0,0,0,0.0666666666666667,0.968627450980392,0.827450980392157,0.325490196078431,0,0,0.329411764705882,0.886274509803922;0.682352941176471,0.239215686274510,0.235294117647059,0,0.462745098039216,0.352941176470588,0.231372549019608,NaN,0.156862745098039,0,0,0,0.125490196078431,0.976470588235294,NaN,0.913725490196078,0.0117647058823529,0.129411764705882,0.129411764705882,0.800000000000000;0.937254901960784,0.674509803921569,0.0431372549019608,0.247058823529412,NaN,0.882352941176471,0.0941176470588235,0.976470588235294,0.403921568627451,0,0,0,0.376470588235294,NaN,NaN,0.603921568627451,0,0.317647058823529,0.960784313725490,0.960784313725490;0.984313725490196,0.121568627450980,0,0.447058823529412,NaN,NaN,0.407843137254902,0.266666666666667,0.258823529411765,0,0,0.0549019607843137,0.858823529411765,NaN,0.854901960784314,0.0627450980392157,0.0156862745098039,0.298039215686275,0.996078431372549,NaN;NaN,0.345098039215686,0,0.0313725490196078,0.717647058823529,NaN,NaN,0.305882352941177,0,0,0.164705882352941,0.784313725490196,NaN,0.858823529411765,0.109803921568627,0,0.384313725490196,0.890196078431373,NaN,NaN;NaN,0.862745098039216,0.0431372549019608,0,0,0.368627450980392,0.827450980392157,NaN,0.945098039215686,0.894117647058824,NaN,NaN,0.592156862745098,0.00784313725490196,0.0117647058823529,0.203921568627451,0.662745098039216,NaN,NaN,NaN;NaN,NaN,0.698039215686275,0,0,0,0,0.188235294117647,0.329411764705882,0.392156862745098,0.317647058823529,0.0823529411764706,0.0274509803921569,0.431372549019608,0.615686274509804,0.682352941176471,0.937254901960784,NaN,NaN,NaN;NaN,NaN,NaN,0.709803921568628,0.341176470588235,0,0,0,0.0313725490196078,0,0.266666666666667,0.372549019607843,0.537254901960784,0.690196078431373,0.937254901960784,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,0.972549019607843,0.592156862745098,0.109803921568627,0.0745098039215686,0.501960784313726,0.631372549019608,0.400000000000000,0.721568627450980,0.819607843137255,0.952941176470588,0.964705882352941,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,0.972549019607843,0.913725490196078,0.843137254901961,NaN,0.929411764705882,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;];
CDataVisible(:,:,2)=[NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.964705882352941,0.886274509803922,0.811764705882353,0.721568627450980,0.650980392156863,0.635294117647059,0.721568627450980,0.862745098039216,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.858823529411765,0.596078431372549,0.462745098039216,0.356862745098039,0.262745098039216,0.196078431372549,0.176470588235294,0.262745098039216,0.431372549019608,0.709803921568628,NaN,NaN,NaN;NaN,NaN,NaN,NaN,0.992156862745098,0.600000000000000,0.168627450980392,0,0,0,0,0,0,0,0,0,0,0.258823529411765,0.905882352941177,NaN;NaN,NaN,NaN,0.843137254901961,0.227450980392157,0,0,0,0,0,0,0,0,0,0,0,0,0,0.372549019607843,NaN;NaN,NaN,0.729411764705882,0.0509803921568627,0,0,0,0,0,0,0,0,0.0274509803921569,0.211764705882353,0.00392156862745098,0,0,0.0745098039215686,0.874509803921569,NaN;NaN,0.650980392156863,0,0,0,0,0.0392156862745098,0.168627450980392,0,0,0,0,0.0666666666666667,0.968627450980392,0.827450980392157,0.325490196078431,0,0,0.329411764705882,0.886274509803922;0.682352941176471,0.239215686274510,0.235294117647059,0,0.462745098039216,0.352941176470588,0.231372549019608,NaN,0.156862745098039,0,0,0,0.125490196078431,0.976470588235294,NaN,0.913725490196078,0.0117647058823529,0.129411764705882,0.129411764705882,0.800000000000000;0.937254901960784,0.674509803921569,0.0431372549019608,0.247058823529412,NaN,0.882352941176471,0.0941176470588235,0.976470588235294,0.403921568627451,0,0,0,0.376470588235294,NaN,NaN,0.603921568627451,0,0.317647058823529,0.960784313725490,0.960784313725490;0.984313725490196,0.121568627450980,0,0.447058823529412,NaN,NaN,0.407843137254902,0.266666666666667,0.258823529411765,0,0,0.0549019607843137,0.858823529411765,NaN,0.854901960784314,0.0627450980392157,0.0156862745098039,0.298039215686275,0.996078431372549,NaN;NaN,0.345098039215686,0,0.0313725490196078,0.717647058823529,NaN,NaN,0.305882352941177,0,0,0.164705882352941,0.784313725490196,NaN,0.858823529411765,0.109803921568627,0,0.384313725490196,0.890196078431373,NaN,NaN;NaN,0.862745098039216,0.0431372549019608,0,0,0.368627450980392,0.827450980392157,NaN,0.945098039215686,0.894117647058824,NaN,NaN,0.592156862745098,0.00784313725490196,0.0117647058823529,0.203921568627451,0.662745098039216,NaN,NaN,NaN;NaN,NaN,0.698039215686275,0,0,0,0,0.188235294117647,0.329411764705882,0.392156862745098,0.317647058823529,0.0823529411764706,0.0274509803921569,0.431372549019608,0.615686274509804,0.682352941176471,0.937254901960784,NaN,NaN,NaN;NaN,NaN,NaN,0.709803921568628,0.341176470588235,0,0,0,0.0313725490196078,0,0.266666666666667,0.372549019607843,0.537254901960784,0.690196078431373,0.937254901960784,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,0.972549019607843,0.592156862745098,0.109803921568627,0.0745098039215686,0.501960784313726,0.631372549019608,0.400000000000000,0.721568627450980,0.819607843137255,0.952941176470588,0.964705882352941,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,0.972549019607843,0.913725490196078,0.843137254901961,NaN,0.929411764705882,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;];
CDataVisible(:,:,3)=[NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.964705882352941,0.886274509803922,0.811764705882353,0.721568627450980,0.650980392156863,0.635294117647059,0.721568627450980,0.862745098039216,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.858823529411765,0.596078431372549,0.462745098039216,0.356862745098039,0.262745098039216,0.196078431372549,0.176470588235294,0.262745098039216,0.431372549019608,0.709803921568628,NaN,NaN,NaN;NaN,NaN,NaN,NaN,0.992156862745098,0.600000000000000,0.168627450980392,0,0,0,0,0,0,0,0,0,0,0.258823529411765,0.905882352941177,NaN;NaN,NaN,NaN,0.843137254901961,0.227450980392157,0,0,0,0,0,0,0,0,0,0,0,0,0,0.372549019607843,NaN;NaN,NaN,0.729411764705882,0.0509803921568627,0,0,0,0,0,0,0,0,0.0274509803921569,0.211764705882353,0.00392156862745098,0,0,0.0745098039215686,0.874509803921569,NaN;NaN,0.650980392156863,0,0,0,0,0.0392156862745098,0.168627450980392,0,0,0,0,0.0666666666666667,0.968627450980392,0.827450980392157,0.325490196078431,0,0,0.329411764705882,0.886274509803922;0.682352941176471,0.239215686274510,0.235294117647059,0,0.462745098039216,0.352941176470588,0.231372549019608,NaN,0.156862745098039,0,0,0,0.125490196078431,0.976470588235294,NaN,0.913725490196078,0.0117647058823529,0.129411764705882,0.129411764705882,0.800000000000000;0.937254901960784,0.674509803921569,0.0431372549019608,0.247058823529412,NaN,0.882352941176471,0.0941176470588235,0.976470588235294,0.403921568627451,0,0,0,0.376470588235294,NaN,NaN,0.603921568627451,0,0.317647058823529,0.960784313725490,0.960784313725490;0.984313725490196,0.121568627450980,0,0.447058823529412,NaN,NaN,0.407843137254902,0.266666666666667,0.258823529411765,0,0,0.0549019607843137,0.858823529411765,NaN,0.854901960784314,0.0627450980392157,0.0156862745098039,0.298039215686275,0.996078431372549,NaN;NaN,0.345098039215686,0,0.0313725490196078,0.717647058823529,NaN,NaN,0.305882352941177,0,0,0.164705882352941,0.784313725490196,NaN,0.858823529411765,0.109803921568627,0,0.384313725490196,0.890196078431373,NaN,NaN;NaN,0.862745098039216,0.0431372549019608,0,0,0.368627450980392,0.827450980392157,NaN,0.945098039215686,0.894117647058824,NaN,NaN,0.592156862745098,0.00784313725490196,0.0117647058823529,0.203921568627451,0.662745098039216,NaN,NaN,NaN;NaN,NaN,0.698039215686275,0,0,0,0,0.188235294117647,0.329411764705882,0.392156862745098,0.317647058823529,0.0823529411764706,0.0274509803921569,0.431372549019608,0.615686274509804,0.682352941176471,0.937254901960784,NaN,NaN,NaN;NaN,NaN,NaN,0.709803921568628,0.341176470588235,0,0,0,0.0313725490196078,0,0.266666666666667,0.372549019607843,0.537254901960784,0.690196078431373,0.937254901960784,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,0.972549019607843,0.592156862745098,0.109803921568627,0.0745098039215686,0.501960784313726,0.631372549019608,0.400000000000000,0.721568627450980,0.819607843137255,0.952941176470588,0.964705882352941,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,0.972549019607843,0.913725490196078,0.843137254901961,NaN,0.929411764705882,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;];
for i=1:ListLength
    fgcolor=[1 1 1];
    enableText='inactive';    
    enable='on';    
    bgcolor=get(slider,'Background');    
    switch(List(i+ListBegin).Selected)
        case 2
            bgcolor=[0.8 0 0];
        case 1
            bgcolor=[0 0 0.8];
        case 0
            fgcolor=[0 0 0];
        otherwise
            bgcolor=get(slider,'Background');
            enable='off';
            enableText='off';  
    end
    if List(i+ListBegin).Visible
        CData=CDataVisible;
    else
        CData=[];        
    end
    set(hList.Pan(i),'Visible','on','UIContextMenu',UIContext);    
    set(hList.Visible(i),'Enable',enable,'CData',CData,'UIContextMenu',UIContext);        
    set(hList.Name(i),'Enable',enableText,'BackgroundColor',bgcolor,'ForegroundColor',fgcolor,'UIContextMenu',UIContext,'String',List(i+ListBegin).Name);
    set(hList.File(i),'Enable',enableText,'BackgroundColor',bgcolor,'ForegroundColor',fgcolor,'UIContextMenu',UIContext,'String',List(i+ListBegin).File);
    set(hList.Back(i),'BackgroundColor',bgcolor);            
    set(hList.Button(i),'Enable',enable,'UIContextMenu',UIContext);
end
for i=ListLength+1:8
    set(hList.Pan(i),'Visible','off');    
end

function QueueSlider
Mode=get(gcbo,'UserData');
UpdateQueue(Mode);
fShared('ReturnFocus');

function UpdateQueue(mode)
hMainGui=getappdata(0,'hMainGui');
global Queue;
if strcmp(mode,'Local');
    hQueue=hMainGui.RightPanel.pQueue.LocList;
    slider=hMainGui.RightPanel.pQueue.sLocList;
    NewQueue=Queue;
else
    DirServer = fShared('CheckServer');
    hQueue=hMainGui.RightPanel.pQueue.SrvList;
    slider=hMainGui.RightPanel.pQueue.sSrvList;
    [NewQueue,Status]=fGetServerQueue;
end    
l=length(NewQueue);
if l>9
    slider_step(1) = 1/(l-9);
    slider_step(2) = 9/(l-9);
    if strcmp(get(slider,'Enable'),'on')==1
        v=get(slider,'Value');
        if v>l-8
            v=l-8;
        end
    else
        v=l-8;
    end
    set(slider,'sliderstep',slider_step,'max',l-8,'min',1,'Value',v,'Enable','on')
    QueueBegin=(l-8)-round(get(slider,'Value'));
    QueueLength=9;
else
    slider_step(1) = 0.1;
    slider_step(2) = 0.1;
    set(slider,'sliderstep',slider_step,...
         'max',1,'min',0,'Value',1,'Enable','off')
     QueueLength=l;
     QueueBegin=0;
end
for i=1:QueueLength
    bgcolor=get(slider,'Background');    
    fgcolor=[1 1 1];
    switch(NewQueue(i+QueueBegin).Selected)
        case 1
            bgcolor=[0 0 0.8];
        case 0
            fgcolor=[0 0 0];
    end            
    if strcmp(mode,'Local')
        set(hQueue.Pan(i),'Visible','on','UIContextMenu',hMainGui.Menu.ctListLoc);    
        set(hQueue.Name(i),'Enable','inactive','BackgroundColor',bgcolor,'ForegroundColor',fgcolor,'UIContextMenu',hMainGui.Menu.ctListLoc,'String',NewQueue(i+QueueBegin).StackName);
        set(hQueue.File(i),'Enable','inactive','BackgroundColor',bgcolor,'ForegroundColor',fgcolor,'UIContextMenu',hMainGui.Menu.ctListLoc,'String',NewQueue(i+QueueBegin).Directory);
        set(hQueue.Back(i),'BackgroundColor',bgcolor,'UIContextMenu',hMainGui.Menu.ctListLoc); 
    else
        set(hQueue.Pan(i),'Visible','on');    
        set(hQueue.Name(i),'Enable','inactive','BackgroundColor',bgcolor,'ForegroundColor',fgcolor,'String',NewQueue(i+QueueBegin).StackName);
        set(hQueue.File(i),'BackgroundColor',bgcolor,'ForegroundColor',fgcolor,'Enable','inactive','String','');
        set(hQueue.Back(i),'BackgroundColor',bgcolor); 
    end
end
for i=QueueLength+1:9
    set(hQueue.Pan(i),'Visible','off');
end
if strcmp(mode,'Local')
    enable='off';
    if l>0
        enable='on';
    end
    set(hMainGui.Menu.mAnalyseQueue,'Enable',enable);
    set(hMainGui.RightPanel.pButton.bAnalyse,'Enable',enable);
else
    for n=1:length(Status)
        dirStatus = [DirServer 'Queue' filesep 'Job' int2str(Status(n).JobNr) filesep 'Status'];
        if isdir(dirStatus) && ~isempty(Status(n).FramesT)
            files = dir([dirStatus filesep '*.mat']);
            Status(n).StatusT = length(files)/Status(n).FramesT;
        else
            Status(n).StatusT = 0;
        end
        if isnan(Status(n).StatusT)
            Status(n).StatusT = 0;
        end
        if strcmp(get(slider,'Enable'),'on')==1 && l>9
            QueueNr = v-l+8 + n;
        else
            QueueNr=n;
        end
        if QueueNr>0
            set(hQueue.File(QueueNr),'String',{sprintf('Tracking: %3.0f%% (%s)',Status(n).StatusT*100,getTime(Status(n).TimeT,Status(n).StatusT)),...
                                               sprintf('Connecting: %3.0f%% (%s)',Status(n).StatusC*100,getTime(Status(n).TimeC,Status(n).StatusC)),...
                                               sprintf('Postprocessing: %3.0f%% (%s)',Status(n).StatusP*100,getTime(Status(n).TimeP,Status(n).StatusP))});
        end                                  
    end
end

function timeleft = getTime(starttime,status)
if status>0
    runtime = etime(clock,starttime);
    if runtime>0
        timeleft = sec2timestr( runtime/status - runtime );
    else
        timeleft = '??:??:??';
    end
else
    timeleft = '??:??:??';
end

function RefreshServerQueue(hMainGui)
DirServer = fShared('CheckServer');
if isempty(DirServer)
    fShared('ReturnFocus');
    return;
end
set(hMainGui.RightPanel.pQueue.bSrvRefresh,'String','Refresh SERVER Queue');
UpdateQueue('Server');
fShared('ReturnFocus');

function LoadQueue
global Queue;
[FileName, PathName] = uigetfile({'*.mat','FIESTA Queue(*.mat)'},'Load FIESTA Queue',fShared('GetLoadDir'));
if FileName~=0
    fShared('SetLoadDir',PathName);
    Queue=fLoad([PathName FileName],'Queue');
    UpdateQueue('Local');    
end
fShared('ReturnFocus');

function SaveQueue
global Queue;
if ~isempty(Queue)
    [FileName, PathName] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save FIESTA Queue',fShared('GetSaveDir'));
    if FileName~=0
        file = [PathName FileName];
        if isempty(findstr('.mat',file))
            file = [file '.mat'];
        end
        fShared('SetSaveDir',PathName);
        save(file,'Queue');
    end
end
fShared('ReturnFocus');

function timestr = sec2timestr(sec)
% Convert seconds to hh:mm:ss
h = floor(sec/3600); % Hours
sec = sec - h*3600;
m = floor(sec/60); % Minutes
sec = sec - m*60;
s = floor(sec); % Seconds

if isnan(sec),
    h = 0;
    m = 0;
    s = 0;
end

if h < 10; h0 = '0'; else h0 = '';end     % Put leading zero on hours if < 10
if m < 10; m0 = '0'; else m0 = '';end     % Put leading zero on minutes if < 10
if s < 10; s0 = '0'; else s0 = '';end     % Put leading zero on seconds if < 10
timestr = strcat(h0,num2str(h),':',m0,...
          num2str(m),':',s0,num2str(s));
