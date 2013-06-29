function abort=fAnalyseStack(Stack,StackInfo,Config,JobNr,Objects)
global logfile;
global error_events;
global DirCurrent;
global FiestaDir;

error_events=[];
abort=0;

if strcmp(Config.Threshold.Mode,'constant')
    params.threshold=Config.Threshold.Value;
end

if max(max(Config.Region))==1
    params.bw_regions=Config.Region;
end

params.bead_model=Config.Model;
params.max_beads_per_region=Config.MaxFunc;
params.scale=Config.PixSize;
params.ridge_model = 'quadratic';


params.find_molecules=1;
params.find_beads=1;

if Config.OnlyTrackMol==1
    params.find_molecules=0;
end
if Config.OnlyTrackFil==1
    params.find_beads=0;
end

params.area_threshold=Config.Threshold.Area;
params.height_threshold=Config.Threshold.Height;   
params.fwhm_estimate=Config.Threshold.FWHM;
if isempty(Config.BorderMargin)
    params.border_margin = 2 * Config.Threshold.FWHM / params.scale / (2*sqrt(2*log(2)));
else
    params.border_margin = Config.BorderMargin;
end

if isempty(Config.ReduceFitBox)
    params.reduce_fit_box = 1;
else
    params.reduce_fit_box = Config.ReduceFitBox;
end


params.focus_correction = Config.FilFocus;
params.min_cod=Config.Threshold.Fit;
params.binary_image_processing=Config.Threshold.Filter;
params.display = 1;

params.options = optimset( 'Display', 'off','UseParallel','always');
params.options.MaxFunEvals = []; 
params.options.MaxIter = [];
params.options.TolFun = [];
params.options.TolX = [];

if ~isempty(StackInfo)
    params.creation_time_vector = (StackInfo.CreationTime-StackInfo.CreationTime(1))/1000;
    %check wether imaging was done during change of date 
    k = params.creation_time_vector<0;
    params.creation_time_vector(k) = params.creation_time_vector(k) + 24*60*60;
end


if isinf(Config.LastFrame)
    Config.LastFrame = length(Stack);
end
if isreal(Config.Threshold.Value)
    params.threshold = Config.Threshold.Value;
else
    minStack = Inf;
    for n = 1:length(Stack)
        params.threshold(n) = mean2(Stack{n});
        minStack(n) =min(min(Stack{n}));
    end
    params.threshold = round( (params.threshold-mean(minStack))*imag(Config.Threshold.Value)/100 + mean(minStack) );
end

if isempty(Objects)
    Objects = cell(size(Stack));
end
if ~isempty(strfind(Config.StackName,'.stk'))
    sName = strrep(Config.StackName, '.stk', '');
elseif ~isempty(strfind(Config.StackName,'.tif'))
    sName = strrep(Config.StackName, '.tif', '');
else
    sName = Config.StackName;
end
try
    fData=[Config.Directory sName '(' datestr(clock,'yyyymmddTHHMMSS') ').mat'];
    save(fData,'-v6','Config');
catch
    fData=[DirCurrent sName '(' datestr(clock,'yyyymmddTHHMMSS') ').mat'];
    fMsgDlg(['Directory not accessible - File saved in FIESTA directory: ' DirCurrent],'warn');
    save(fData,'-v6','Config');
end
filestr = [FiestaDir.AppData 'logfile.txt'];
logfile = fopen(filestr,'w');
if Config.FirstTFrame>0
    FramesT = min([Config.LastFrame length(Stack)])-Config.FirstTFrame+1;
    if JobNr>0
        params.display = 0;
        dirStatus = [DirCurrent 'Queue' filesep 'Job' int2str(JobNr) filesep 'Status' filesep];
        TimeT = clock; %#ok<NASGU>
        save([DirCurrent 'Queue' filesep 'Job' int2str(JobNr) filesep 'FiestaStatus.mat'],'TimeT','FramesT','-append');
        try
            parfor n=Config.FirstTFrame:min([Config.LastFrame length(Stack)])
                Objects{n}=ScanImage(Stack{n},params,n);
                fSave(dirStatus,n);
            end
        catch ME
            save(fData,'-append','-v6','Objects','ME');
            return;
        end
    else
        workbar(0,sprintf('Tracking - Frame: %d',Config.FirstTFrame),'Progress',0)
        for n=Config.FirstTFrame:min([Config.LastFrame length(Stack)])
            Log(sprintf('Analysing frame %d',n),params);
            try
                Objects{n}=ScanImage(Stack{n},params,n);
            catch ME
                save(fData,'-append','-v6','Objects','ME');
                return;
            end
            drawnow;
            if n>Config.FirstTFrame
                h = findobj('Tag','timebar');
                if isempty(h)
                    abort=1;
                    return
                end
            end
            if Config.FirstCFrame>0
                if ~isempty(Objects{n})
                    s=sprintf('Tracking - Frame: %d - Objects found: %d',n+1,length(Objects{n}.center_x));
                else
                    s=sprintf('Tracking - Frame: %d - Objects found: %d',n+1,0);
                end
                StatusT = (n-Config.FirstTFrame+1)/FramesT;
                workbar(StatusT,s,'Progress',-1)
            end
        end
    end
end
workbar(1,'','Progress',0)
fclose(logfile);
disp(Config.StackName)
disp(error_events)
if Config.LastFrame>length(Stack)&&Config.FirstTFrame>0
    fMsgDlg(['Warning out of memory - Only tracked till frame number ' num2str(length(Stack))],'warn');
end
try
    save(fData,'-append','-v6','Objects');
catch
    fData=[DirCurrent sName '(' datestr(clock,'yyyymmddTHHMMSS') ').mat'];
    fMsgDlg(['Directory not accessible - File saved in FIESTA directory: ' DirCurrent],'warn');
    save(fData,'-v6','Objects','Config');
end
if ~isempty(Objects)
    try
        [MolTrack,FilTrack,abort]=fFeatureConnect(Objects,Config,JobNr);
    catch ME
        save(fData,'-v6','ME','-append');
        return;
    end
    if abort==1
        return
    end
    Molecule=[];
    Filament=[];
    Molecule=fDefStructure(Molecule,'Molecule');
    Filament=fDefStructure(Filament,'Filament');
    nMolTrack=length(MolTrack);
    for n = 1:nMolTrack
        nData=size(MolTrack{n},1);
        Molecule(n).Name = ['Molecule ' num2str(n)];
        Molecule(n).File = Config.StackName;
        Molecule(n).Directory = Config.Directory;
        
        Molecule(n).Selected = 0;
        Molecule(n).Visible = 1;    
        Molecule(n).Drift = 0;            
        Molecule(n).PixelSize = Config.PixSize;    
        
        Molecule(n).Color = [0 0 1];
        
        for j = 1:nData
            f = MolTrack{n}(j,1);
            m = MolTrack{n}(j,2);
            
            Molecule(n).Results(j,1) = single(f);
            Molecule(n).Results(j,2) = Objects{f}.time;
            Molecule(n).Results(j,3) = Objects{f}.center_x(m);
            Molecule(n).Results(j,4) = Objects{f}.center_y(m);
            Molecule(n).Results(j,5) = single(norm([Molecule(n).Results(j,3)-Molecule(n).Results(1,3) Molecule(n).Results(j,4)-Molecule(n).Results(1,4)]));
            Molecule(n).Results(j,6) = Objects{f}.width(1,m);
            Molecule(n).Results(j,7) = Objects{f}.height(1,m);                
            Molecule(n).Results(j,8) = single(sqrt((Objects{f}.com_x(2,m))^2+(Objects{f}.com_y(2,m))^2));
                                        
            if size(Objects{f}.data{m},2)==1
                Molecule(n).Results(j,9:10) = Objects{f}.data{m}';                
                Molecule(n).Results(j,11) = single(mod(Objects{f}.orientation(1,m),2*pi));                
                Molecule(n).Type = 'stretched';
            elseif size(Objects{f}.data{m},2)==3
                Molecule(n).Results(j,9:11) = Objects{f}.data{m}(1,:);                
                Molecule(n).Type = 'ring1';
                if size(Objects{f}.data{m},1)>1
                    Molecule(n).Results(j,12:14) = Objects{f}.data{m}(2,:);
                    Molecule(n).Type = 'ring2';
                end
            else
                Molecule(n).Type = 'symmetric';
            end
        end
    end
    if ~isempty(Stack)
        sStack=size(Stack{1});
    end
    nFilTrack=length(FilTrack);
    for n = nFilTrack:-1:1
        nData=size(FilTrack{n},1);
        Filament(n).Name = ['Filament ' num2str(n)];
        Filament(n).File = Config.StackName;
        Filament(n).Directory = Config.Directory;
        
        Filament(n).Selected=0;
        Filament(n).Visible=1;    
        Filament(n).Drift=0;    
        Filament(n).PixelSize = Config.PixSize;    
        
        Filament(n).Color=[0 0 1];
        
        for j=1:nData
            f = FilTrack{n}(j,1);
            m = FilTrack{n}(j,2);
                    
            Filament(n).Results(j,1) = single(f);
            Filament(n).Results(j,2) = Objects{f}.time;
            Filament(n).Results(j,3) = Objects{f}.center_x(m);
            Filament(n).Results(j,4) = Objects{f}.center_y(m);
            Filament(n).Results(j,6) = Objects{f}.length(1,m);
            Filament(n).Results(j,7) = Objects{f}.height(1,m);                
            Filament(n).Results(j,8) = single(mod(Objects{f}.orientation(1,m),2*pi));
            Filament(n).Data{j} = Objects{f}.data{m};
            Filament(n).PosCenter(j,1:2)=Filament(n).Results(j,3:4);   
        end
        
        Filament(n) = fAlignFilament(Filament(n),Config);
        
        if Config.ConnectFil.DisregardEdge && ~isempty(Stack)                                          
            xv = [5 5 sStack(2)-4 sStack(2)-4]*Config.PixSize;
            yv = [5 sStack(1)-4 sStack(1)-4 5]*Config.PixSize;            
            X=Filament(n).PosStart(:,1);
            Y=Filament(n).PosStart(:,2);
            IN = inpolygon(X,Y,xv,yv);
            Filament(n).Results(~IN,:)=[];            
            Filament(n).PosStart(~IN,:)=[];
            Filament(n).PosCenter(~IN,:)=[];
            Filament(n).PosEnd(~IN,:)=[];
            Filament(n).Data(~IN)=[];            
            X=Filament(n).PosEnd(:,1);
            Y=Filament(n).PosEnd(:,2);
            IN = inpolygon(X,Y,xv,yv);
            Filament(n).Results(~IN,:)=[];
            Filament(n).PosStart(~IN,:)=[];
            Filament(n).PosCenter(~IN,:)=[];
            Filament(n).PosEnd(~IN,:)=[]; 
            Filament(n).Data(~IN)=[];
            if isempty(Filament(n).Results)
                Filament(n)=[];
            else
                Filament(n).Results(:,5) = single(sqrt( (Filament(n).Results(:,3)-Filament(n).Results(1,3)).^2 + (Filament(n).Results(:,4)-Filament(n).Results(1,4)).^2));
            end
        end
    end
    try
        save(fData,'-append','-v6','Molecule','Filament');
    catch ME
        fData=[DirCurrent sName '(' datestr(clock,'yyyymmddTHHMMSS') ').mat'];
        fMsgDlg(['Directory not accessible - File saved in FIESTA directory: ' DirCurrent],'warn');
        save(fData,'-v6','Molecule','Filament','Objects','Config');
    end
    clear Molecule Filament Objects Config;
end

function fSave(dirStatus,frame)
fname = [dirStatus 'frame' int2str(frame) '.mat'];
save(fname,'frame');