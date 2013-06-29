function fMenuData(func,varargin)
switch func
    case 'OpenStack'
        OpenStack(varargin{1});
    case 'SaveStack'
        SaveStack(varargin{1}); 
    case 'CloseStack'
        CloseStack(varargin{1});
    case 'LoadTracks'
        LoadTracks(varargin{1});
    case 'ImportTracks'
        ImportTracks(varargin{1});        
    case 'SaveTracks'
        SaveTracks(varargin{1}); 
    case 'SaveText'
        SaveText(varargin{1});         
    case 'ClearTracks'
        ClearTracks(varargin{1}); 
    case 'LoadObjects'
        LoadObjects(varargin{1});  
    case 'SaveObjects'
        SaveObjects(varargin{1});          
    case 'ClearObjects'
        ClearObjects(varargin{1});          
    case 'Export'
        Export(varargin{1});          
end

function OpenStack(hMainGui)
global Stack;
global StackInfo;
global Config;
global Molecule;
global Filament;
global FiestaDir;
set(hMainGui.MidPanel.pNoData,'Visible','on')
set(hMainGui.MidPanel.tNoData,'String','Loading Stack...','Visible','on');
set(hMainGui.MidPanel.pView,'Visible','off');
[FileName,PathName] = uigetfile({'*.stk;*.zvi;*.tif;*.tiff','Image Stacks (*.stk,*.zvi,*.tif,*.tiff)'},'Select the Stack',FiestaDir.Stack); %open dialog for *.stk files 
if PathName~=0
    if ~isempty(strfind(FileName,'.stk'))
        filetype = 'MetaMorph';
        Config.Time =[];
    elseif ~isempty(strfind(FileName,'.zvi'))
        filetype = 'AxioVision';
        Config.Time =[];
    else
        Config.Time = str2double(fInputDlg('Enter plane time difference in ms:','100'));
        filetype = 'TIFF';
    end
    PixSize = str2double(fInputDlg('Enter Pixel Size in nm:','100'));
    if isempty(PixSize)
        PathName=0;
    end
end
if PathName~=0
    set(hMainGui.fig,'Pointer','watch');   
    CloseStack(hMainGui);
    hMainGui=getappdata(0,'hMainGui');
    Config.PixSize=PixSize;
    failed=0;
    FiestaDir.Stack=PathName;
    f=[PathName FileName];
    try
        [Stack,StackInfo,Values]=fStackRead(f);  %#ok<ASGLU>
    catch ME   
        fMsgDlg(ME.message,'error');
        failed=1;
    end
    if isfield(StackInfo,'CreationTime')
        if length(unique(StackInfo.CreationTime))<length(StackInfo.CreationTime)
            Config.Time = str2double(fInputDlg('Creation time corrupt - Enter plane time difference in ms:','100'));    
        end
    end
    if ~isempty(Config.Time)             
        nFrames=length(Stack);
        StackInfo.CreationTime=(0:nFrames-1)*Config.Time;
    end
    if failed==0&&~isempty(Stack)
        set(hMainGui.fig,'Name',[hMainGui.Name ':' FileName]);
        Config.StackName=FileName;
        Config.Directory=PathName;
        hMainGui.Directory.Stack=PathName;
        Config.StackType=filetype;
        hMainGui.Values.PixSize=Config.PixSize;
        set(hMainGui.Menu.mRedGreenOverlay,'Checked','off');
        hMainGui.Values.Stack=1;
        fMainGui('InitGui',hMainGui,Values);
    end
else
    if ~isempty(Stack)||~isempty(Molecule)||~isempty(Filament)
        set(hMainGui.MidPanel.pView,'Visible','on');
        set(hMainGui.MidPanel.tNoData,'Visible','off');        
        set(hMainGui.MidPanel.tNoData,'String','No Stack or Tracks present','Visible','off');    
    else
        set(hMainGui.MidPanel.pView,'Visible','off');
        set(hMainGui.MidPanel.tNoData,'Visible','on');        
        set(hMainGui.MidPanel.tNoData,'String','No Stack or Tracks present','Visible','on');    
    end
end
set(hMainGui.fig,'Pointer','arrow');


function SaveStack(hMainGui)
global Stack;
global FiestaDir
[FileName,PathName] = uiputfile({'*.tif','Multilayer TIFF-Files (*.tif)'},'Create New TIFF',FiestaDir.Stack); %open dialog for *.stk files 
if FileName~=0
    set(hMainGui.fig,'Pointer','watch');    
    file = [PathName FileName];
    if isempty(findstr('.tif',file))
        file = [file '.tif'];
    end
    h = waitbar(0,'Please wait...');
    for i=1:length(Stack)
        if i==1
            imwrite(Stack{i},file,'tiff','Compression','none','WriteMode','overwrite');
        else
            imwrite(Stack{i},file,'tiff','Compression','none','WriteMode','append');
        end
        waitbar(i/length(Stack))
    end
    close(h);
    set(hMainGui.fig,'Pointer','arrow');
end
    
function CloseStack(hMainGui)
global Stack;
global StackInfo;
global Molecule;
global Filament;
if ~isempty(Stack)
    Stack=[];
    StackInfo=[];
    hMainGui.Values.FrameIdx=0;
    hMainGui.Values.Stack=0;
    hMainGui.Values.PixSize=1;
    hMainGui=DeleteAllRegions(hMainGui);    
    setappdata(hMainGui.fig,'Stack',Stack);
    setappdata(hMainGui.fig,'StackInfo',StackInfo);
    set(hMainGui.MidPanel.sFrame,'Enable','off');
    set(hMainGui.MidPanel.eFrame,'Enable','off','String','');  
    set(hMainGui.fig,'Name',hMainGui.Name);
    fRightPanel('AllToolsOff',hMainGui);
    fLeftPanel('DisableAllPanels',hMainGui);
    hMainGui=getappdata(0,'hMainGui');
    fShared('DeleteScan',hMainGui);
    hMainGui=getappdata(0,'hMainGui');
    hMainGui.Measure=[];
    hMainGui.Plots.Measure=[];
    try
        delete(hMainGui.Image);
    catch
    end
    hMainGui.Image=[];
    hMainGui.Value.PixSize=1;
    delete(findobj('Parent',hMainGui.MidPanel.aView,'Tag','pObjects'));
    if isempty(Molecule)&&isempty(Filament)
        set(hMainGui.MidPanel.pView,'Visible','Off');
        set(hMainGui.MidPanel.pNoData,'Visible','On');
        set(hMainGui.MidPanel.tNoData,'String','No Stack or Tracks present','Visible','on');          
    end
    setappdata(0,'hMainGui',hMainGui);
    fShared('UpdateMenu',hMainGui);   
    fShow('Tracks');
end

function hMainGui=DeleteAllRegions(hMainGui)
nRegion=length(hMainGui.Region);
for i=nRegion:-1:1
    hMainGui.Region(i)=[];
    try
        delete(hMainGui.Plots.Region(i));
        hMainGui.Plots.Region(i)=[];
    catch
    end
end
fLeftPanel('RegUpdateList',hMainGui);

function LoadTracks(hMainGui)
global Stack
global Molecule;
global Filament;
global Config;
fRightPanel('CheckDrift',hMainGui);
Mode=get(gcbo,'UserData');
set(hMainGui.MidPanel.pNoData,'Visible','on')
set(hMainGui.MidPanel.tNoData,'String','Loading Data...','Visible','on');
set(hMainGui.MidPanel.pView,'Visible','off');
if strcmp(Mode,'local')
    LoadDir = fShared('GetLoadDir');
else
    DirServer = fShared('CheckServer');
    if ~isempty(DirServer)
        LoadDir = [DirServer 'Data' filesep];
    else
        return;
    end
end
[FileName, PathName] = uigetfile({'*.mat','FIESTA Data(*.mat)'},'Load FIESTA Tracks',LoadDir,'MultiSelect','on');
if ~iscell(FileName)
    FileName={FileName};
end
if PathName~=0
    set(hMainGui.fig,'Pointer','watch');
    if strcmp(Mode,'local')
       fShared('SetLoadDir',PathName);
    end
    FileName = sort(FileName);
    workbar(0/length(FileName),['Loading file 1 of ' num2str(length(FileName)) '...'],'Progress',-1);
    for n = 1 : length(FileName)
        ME = fLoad([PathName FileName{n}],'ME');
        if isempty(ME)
            tempMicrotubule=[];
            [tempMolecule,tempFilament]=fLoad([PathName FileName{n}],'Molecule','Filament');
            if isempty(tempMolecule)&&isempty(tempFilament)
                [tempMolecule,tempFilament,tempMicrotubule]=fLoad([PathName FileName{n}],'sMolecule','sFilament','sMicrotubule');
            end

            if isstruct(tempMicrotubule)&&~isstruct(tempFilament)
                tempFilament=tempMicrotubule;
            end
            if isempty(tempMolecule) && isempty(tempFilament) 
                fMsgDlg({['No tracks in ' FileName{n}],'Check configuration or reconnect objects'},'error');   
            else
                if ~isfield(tempFilament,'Data') && ~isfield(tempFilament,'data')
                    fMsgDlg(['Data in ' FileName{n} ' not compatible with FIESTA - try to Import Data'],'warn');
                else
                    if ~isempty(tempMolecule)
                        tempMolecule = fDefStructure(tempMolecule,'Molecule');
                        Molecule = [Molecule tempMolecule]; %#ok<AGROW>
                    end
                    if ~isempty(tempFilament)
                        tempFilament = fDefStructure(tempFilament,'Filament');
                        Filament = [Filament tempFilament]; %#ok<AGROW>
                        if strcmp(Config.RefPoint,'center') == 1
                            field = 'PosCenter';
                        elseif strcmp(Config.RefPoint,'start') == 1
                            field = 'PosStart';
                        else
                            field = 'PosEnd';
                        end
                        for i = 1:length(Filament)
                            Filament(i).Results(:,3:4) = Filament(i).(field);
                        end
                    end
                end
            end
        else
            fMsgDlg({'FIESTA detected a problem during analysis','',['File: ' FileName{n}(1:end-21)],'','','Error message:','',getReport(ME,'extended','hyperlinks','off')},'error');
        end
        workbar(n/length(FileName),['Loading file ' num2str(n+1) ' of ' num2str(length(FileName)) '...'],'Progress',-1);
    end
    fRightPanel('UpdateList',hMainGui.RightPanel.pData.MolList,Molecule,hMainGui.RightPanel.pData.sMolList,hMainGui.Menu.ctListMol);
    fRightPanel('UpdateList',hMainGui.RightPanel.pData.FilList,Filament,hMainGui.RightPanel.pData.sFilList,hMainGui.Menu.ctListFil);
    hMainGui.ZoomView.level = [];
    setappdata(0,'hMainGui',hMainGui);
    fShared('UpdateMenu',hMainGui);        
    fShow('Image');
    fShow('Tracks');
    set(hMainGui.MidPanel.pView,'Visible','on');
    set(hMainGui.MidPanel.pNoData,'Visible','off')
    set(hMainGui.MidPanel.tNoData,'String','No Stack or Tracks present','Visible','off');      
end
if ~isempty(Stack)||~isempty(Molecule)||~isempty(Filament)
    set(hMainGui.MidPanel.pView,'Visible','on');
    set(hMainGui.MidPanel.pNoData,'Visible','off')
    set(hMainGui.MidPanel.tNoData,'String','No Stack or Tracks present','Visible','off');      
    drawnow expose
else
    set(hMainGui.MidPanel.pView,'Visible','off');
    set(hMainGui.MidPanel.pNoData,'Visible','on')
    set(hMainGui.MidPanel.tNoData,'String','No Stack or Tracks present','Visible','on');      
end
set(hMainGui.fig,'Pointer','arrow');    

    
function ImportTracks(hMainGui)
global Molecule;
global Filament;
global Objects;
global Stack; x
fRightPanel('CheckDrift',hMainGui);
set(hMainGui.MidPanel.pNoData,'Visible','on')
set(hMainGui.MidPanel.tNoData,'String','Loading Data...','Visible','on');
set(hMainGui.MidPanel.pView,'Visible','off');
[FileName, PathName] = uigetfile({'*.mat','FOTS Data(*.mat)'},'Import FOTS Tracks',fShared('GetLoadDir'));    
if FileName~=0
    set(hMainGui.fig,'Pointer','watch');
    fShared('SetLoadDir',PathName);
    Objects=[];
    [sMolecule,sMicrotubule]=fLoad([PathName FileName],'sMolecule','sMicrotubule');
    nsMol=length(sMolecule);
    if nsMol>0
        sMolecule=fDefStructure(sMolecule,'Molecule');
        for i=1:nsMol
            sMolecule(i).Results(:,6)=sqrt(sMolecule(i).Results(:,8).^2+sMolecule(i).Results(:,9).^2)*2*sqrt(log(4));
            sMolecule(i).Results(:,8)=1;
            sMolecule(i).Results(:,9:end)=[];
        end
        sMolecule = [Molecule sMolecule];
        clear Molecule;
        Molecule = sMolecule;
        clear sMolecule;
    end
    sFilament=sMicrotubule;
    nsFil=length(sFilament);
    if nsFil>0
        sFilament=fDefStructure(sFilament,'Filament');
        for i=1:nsFil
            if size(sFilament(i).Results,2)==5
                for j=1:size(sFilament(i).Results,1)
                    MicX=sFilament(i).Frame(sFilament(i).Results(j,1)).Positions(:,2);
                    MicY=sFilament(i).Frame(sFilament(i).Results(j,1)).Positions(:,3);
                    f=1:1:length(MicX);
                    ff=1:0.01:length(MicX);
                    MicXX=spline(f,MicX,ff);
                    MicYY=spline(f,MicY,ff);
                    MicLenVec=sqrt( (MicXX(2:length(MicXX))-MicXX(1:length(MicXX)-1)).^2 +...
                                    (MicYY(2:length(MicYY))-MicYY(1:length(MicYY)-1)).^2);
                    MicLen=sum(MicLenVec);      
                    u=round(length(MicXX)/3);
                    while sum(MicLenVec(1:u))<MicLen/2
                        u=u+1;
                    end
                    sFilament(i).Results(j,3)=single(MicXX(u));
                    sFilament(i).Results(j,4)=single(MicYY(u));
                    sFilament(i).Results(j,6)=single(sum(MicLenVec));
                    sFilament(i).Data{j}(:,1) = single(sFilament(i).Frame(sFilament(i).Results(j,1)).Positions(:,2));
                    sFilament(i).Data{j}(:,2) = single(sFilament(i).Frame(sFilament(i).Results(j,1)).Positions(:,3));
                    sFilament(i).Data{j}(:,3) = single((sFilament(i).Frame(sFilament(i).Results(j,1)).Positions(:,1)-1));
                    sFilament(i).Data{j}(:,4) = single(sFilament(i).Frame(sFilament(i).Results(j,1)).Positions(:,7));
                    sFilament(i).Data{j}(:,6) = single(sFilament(i).Frame(sFilament(i).Results(j,1)).Positions(:,4));
                    sFilament(i).Data{j}(:,5) = single(sFilament(i).Frame(sFilament(i).Results(j,1)).Positions(:,5));
                end
            end
            if (sFilament(i).Results(1,5)~=0)&&size(sFilament(i).Results,2)==6
                h=sFilament(i).Results(:,5);
                sFilament(i).Results(:,5)=single(sObject(i).Results(:,6));
                sFilament(i).Results(:,6)=single(h);
            end
            sFilament(i).PosCenter=sFilament(i).Results(:,3:4);
            sFilament(i).PosStart=sFilament(i).Results(:,3:4);
            sFilament(i).PosEnd=sFilament(i).Results(:,3:4);
        end
        sFilament = [Filament sFilament];
        clear Filament;
        Filament = sFilament;
        clear sFilament;
    end
    fRightPanel('UpdateList',hMainGui.RightPanel.pData.MolList,Molecule,hMainGui.RightPanel.pData.sMolList,hMainGui.Menu.ctListMol);
    fRightPanel('UpdateList',hMainGui.RightPanel.pData.FilList,Filament,hMainGui.RightPanel.pData.sFilList,hMainGui.Menu.ctListFil);
    setappdata(0,'hMainGui',hMainGui);
    fShared('UpdateMenu',hMainGui)
    fShow('Image',hMainGui);
    fShow('Tracks',hMainGui);
    set(hMainGui.MidPanel.pView,'Visible','on');    
    set(hMainGui.MidPanel.pNoData,'Visible','off');
    set(hMainGui.MidPanel.tNoData,'String','No Stack or Tracks present','Visible','off');  
end
if ~isempty(Stack)||~isempty(Molecule)||~isempty(Filament)
    set(hMainGui.MidPanel.pView,'Visible','on');
    set(hMainGui.MidPanel.pNoData,'Visible','off');
    set(hMainGui.MidPanel.tNoData,'String','No Stack or Tracks present','Visible','off');  
    drawnow expose
end 
set(hMainGui.fig,'Pointer','arrow');
    
function SaveTracks(hMainGui)
global Molecule; 
global Filament; 
[FileName, PathName] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save FIESTA Tracks',fShared('GetSaveDir'));
if FileName ~= 0
    if ~isempty(strfind(get(gcbo,'UserData'),'select'))
        backup_Molecule = Molecule;
        backup_Filament = Filament;
        Molecule([Molecule.Selected] ~= 1) = [];
        Filament([Filament.Selected] ~= 1) = [];
    end
    set(gcf,'Pointer','watch');    
    fShared('SetSaveDir',PathName);
    file = [PathName FileName];
    if isempty(findstr('.mat',file))
        file = [file '.mat'];
    end
    save(file,'Molecule','Filament','-v6');
    set(hMainGui.fig,'Pointer','arrow');    
    if ~isempty(strfind(get(gcbo,'UserData'),'select'))
        Molecule = backup_Molecule;
        Filament = backup_Filament;
    end
end

function SaveText(hMainGui)
global Molecule;
global Filament;
if ~isempty(strfind(get(gcbo,'UserData'),'select'))
    kMol = find([Molecule.Selected] == 1);
    kFil = find([Filament.Selected] == 1);
    Mode = strrep(get(gcbo,'UserData'),'select_','');
else
    kMol = 1:length(Molecule);
    kFil = 1:length(Filament);
    Mode = get(gcbo,'UserData');
end
if ~isempty(Molecule) || ~isempty(Filament)
    if strcmp(Mode,'multiple')
        PathName = uigetdir(fShared('GetSaveDir'));
    else
        [FileName, PathName] = uiputfile({'*.txt','Delimeted Text (*.txt)'}, 'Save FIESTA Tracks as...',fShared('GetSaveDir'));
        file = [PathName FileName];
        if isempty(findstr('.txt',file))
            file = [file '.txt'];
        end
    end
    if PathName~=0
        set(gcf,'Pointer','watch');        
        fShared('SetSaveDir',PathName);
        if strcmp(Mode,'single')
            file_id = fopen(file,'w');
        end
        for n = kMol
            if strcmp(Mode,'multiple')
                file = [PathName filesep Molecule(n).Name '.txt'];
                file_id = fopen(file,'w');
            end
            fprintf(file_id,'%s - %s%s\n',Molecule(n).Name,Molecule(n).Directory,Molecule(n).File);
            if isempty(Molecule(n).PathData)
                PathData = [];
                PathHeader = '';
            else
                PathData = Molecule(n).PathData;
                PathHeader = sprintf('\tpath x-position[nm]\tpath y-Position[nm]\tdistance(along path)[nm]\tsideways(to path)[nm]');
            end
            format = '%8f';
            %determine what kind of Molecule found
            if strcmp(Molecule(n).Type,'symmetric')
                fprintf(file_id,'frame\ttime[s]\tx-position[nm]\ty-position[nm]\tdistance(to origin)[nm]\twidth(FWHM)[nm]\tamplitude[ABU]\tintensity(volume)[ABU]\tfit error of center[nm]%s\n',PathHeader);
                data = [Molecule(n).Results(:,1:7) 2*pi*(Molecule(n).Results(:,6)/Molecule(n).PixelSize/(2*sqrt(2*log(2)))).^2.*Molecule(n).Results(:,7) Molecule(n).Results(:,8) PathData];
            elseif strcmp(Molecule(n).Type,'stretched')
                fprintf(file_id,'frame\ttime[s]\tx-position[nm]\ty-position[nm]\tdistance(to origin)[nm]\taverage width(FWHM)[nm]\tamplitude[ABU]\tfit error of center[nm]\twidth of major axis(FWHM)[nm]\twidth of minor axis(FWHM)[nm]\torientation(angle to x-axis)[rad]%s\n',PathHeader);
                data = [Molecule(n).Results PathData];
           elseif strcmp(Molecule(n).Type,'ring1')
                fprintf(file_id,'frame\ttime[s]\tx-position[nm]\ty-position[nm]\tdistance(to origin)[nm]\taverage width(FWHM)[nm]\tamplitude[ABU]\tfit error of center[nm]\tradius of ring[nm]\twidth of ring(FWHM)[nm]\tamplitude of ring[ABU]%s\n',PathHeader);
                data = [Molecule(n).Results PathData];
            else
                fprintf(file_id,'frame\ttime[s]\tx-position[nm]\ty-position[nm]\tdistance(to origin)[nm]\taverage width(FWHM)[nm]\tamplitude[ABU]\tfit error of center[nm]\tradius of inner ring[nm]\twidth of inner ring(FWHM)[nm]\tamplitude of inner ring[ABU]\tradius of outer ring[nm]\twidth of outer ring(FWHM)[nm]\tamplitude of outer ring[ABU]%s\n',PathHeader);
                data = [Molecule(n).Results PathData];
            end
            for m = 2:size(data,2)
                format  = [format '\t%8f']; %#ok<AGROW>
            end
            format = [format '\n']; %#ok<AGROW>
            fprintf(file_id,format,data');
            fprintf(file_id,'\n');
            if strcmp(Mode,'multiple')
                fclose(file_id);
            end
        end
        for n = kFil
            if strcmp(Mode,'multiple')
                file = [PathName filesep Filament(n).Name '.txt'];
                file_id = fopen(file,'w');
            end
            fprintf(file_id,'%s - %s%s\n',Filament(n).Name,Filament(n).Directory,Filament(n).File);
            if isempty(Filament(n).PathData)
                PathData = [];
                PathHeader = '';
            else
                PathData = Filament(n).PathData;
                PathHeader = sprintf('\tpath x-position[nm]\tpath y-Position[nm]\tdistance(along path)[nm]\tsideways(to path)[nm]');
            end
            fprintf(file_id,'track data\n');
            format = '%8f';
            fprintf(file_id,'frame\ttime[s]\tx-position[nm]\ty-position[nm]\tdistance(to origin)[nm]\tlength[nm]\taverage amplitude[ABU]\torientation(angle to x-axis)[rad]%s\n',PathHeader);
            data = [Filament(n).Results PathData];
            for m = 2:size(data,2)
                format  = [format '\t%8f']; %#ok<AGROW>
            end
            format = [format '\n']; %#ok<AGROW>
            fprintf(file_id,format,data');
            fprintf(file_id,'\n');  
            
            for j=1:size(data,1)
                fprintf(file_id,'tracking details\n');
                fprintf(file_id,'frame\ttime[s]\tx-position[nm]\ty-position[nm]\tdistance(to origin)[nm]\tlength[nm]\taverage amplitude[ABU]\torientation(angle to x-axis)[rad]%s\n',PathHeader);
                fprintf(file_id,format,data(j,:)');                
                fprintf(file_id,'x-position[nm]\ty-position[nm]\tdistance to start[nm]\twidth(FWHM)[nm]\tamplitude[ABU]\tbackground[ABU]\n');
                fprintf(file_id,'%8f\t%8f\t%8f\t%8f\t%8f\t%8f\n',Filament(n).Data{j}');
                fprintf(file_id,'\n');            
            end
            if strcmp(Mode,'multiple')
                fclose(file_id);
            end
        end
        if strcmp(Mode,'single')
            fclose(file_id);
        end
    end
end
set(hMainGui.fig,'Pointer','arrow');

function LoadObjects(hMainGui)
global Stack
global Objects;
global Molecule;
global Filament;
set(hMainGui.MidPanel.pNoData,'Visible','on')
set(hMainGui.MidPanel.tNoData,'String','Loading Data...','Visible','on');
set(hMainGui.MidPanel.pView,'Visible','off');
Mode = get(gcbo,'UserData');
if strcmp(Mode,'local')
    LoadDir = fShared('GetLoadDir');
else
    DirServer = fShared('CheckServer');
    if ~isempty(DirServer)
        LoadDir = [DirServer 'Data' filesep];
    else
        return;
    end
end
[FileName, PathName] = uigetfile({'*.mat','FIESTA Data(*.mat)'},'Load FIESTA Objects',LoadDir,'MultiSelect','on');    
if ~iscell(FileName)
    FileName={FileName};
end
if PathName~=0
    set(hMainGui.fig,'Pointer','watch');
    if strcmp(Mode,'local')
       fShared('SetLoadDir',PathName);
    end
    FileName = sort(FileName);
    workbar(0/length(FileName),['Loading file 1 of ' num2str(length(FileName)) '...'],'Progress',-1);
    for n = 1 : length(FileName)
        ME = fLoad([PathName FileName{n}],'ME');
        if ~isempty(ME)
        	fMsgDlg({'FIESTA detected a problem during analysis','',['File: ' FileName{n}(1:end-21)],'','','Error message:','',getReport(ME,'extended','hyperlinks','off')},'error');
        end
        tempObjects = fLoad([PathName FileName{n}],'Objects');
        if isempty(tempObjects)
            tempObjects = fLoad([PathName FileName{n}],'sObjects');
            if isempty(tempObjects)
                fMsgDlg(['No Objects detected in ' FileName{n}],'warn');     
            end
        end
        if ~isempty(tempObjects)
            tempObjects = fConvertObjects(tempObjects);
            for m=1:length(tempObjects)
                if m<=length(Objects)
                    if ~isempty(Objects{m}) 
                        if isempty(tempObjects{m})
                            tempObjects{m} = Objects{m};
                        else
                            name = fieldnames(Objects{m});
                            for k = 1:length(name)
                                if ~strcmp(name{k},'time')
                                    tempObjects{m}.(name{k}) = [Objects{m}.(name{k}) tempObjects{m}.(name{k})];
                                end
                            end
                        end
                    end
                end
            end
            Objects = tempObjects;
        end
        workbar(n/length(FileName),['Loading file ' num2str(n+1) ' of ' num2str(length(FileName)) '...'],'Progress',-1);
    end
    hMainGui.File=FileName{n};
    setappdata(0,'hMainGui',hMainGui);
    fShared('UpdateMenu',hMainGui);   
    if ~isempty(Stack)
        fShow('Image',hMainGui);
        set(hMainGui.MidPanel.pView,'Visible','on');
        set(hMainGui.MidPanel.pNoData,'Visible','off');
        set(hMainGui.MidPanel.tNoData,'String','No Stack or Tracks present','Visible','off');      
    end
end
if ~isempty(Stack)||~isempty(Molecule)||~isempty(Filament)
    set(hMainGui.MidPanel.pView,'Visible','on');
    set(hMainGui.MidPanel.pNoData,'Visible','off');
    set(hMainGui.MidPanel.tNoData,'String','No Stack or Tracks present','Visible','off');      
    drawnow expose
end    
set(hMainGui.fig,'Pointer','arrow');

    
function SaveObjects(hMainGui)
global Objects; %#ok<NUSED>
[FileName, PathName] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save FIESTA Objects',fShared('GetSaveDir'));
if FileName~=0
    set(gcf,'Pointer','watch');
    fShared('SetSaveDir',PathName);
    file = [PathName FileName];
    if isempty(findstr('.mat',file))
        file = [file '.mat'];
    end
    save(file,'Objects','-v6');
    set(hMainGui.fig,'Pointer','arrow');    
end

function ClearObjects(hMainGui)
global Objects;
clear global Objects;
Objects = [];
hMainGui.File=[];
fShared('UpdateMenu',hMainGui);  
fShow('Image',hMainGui);