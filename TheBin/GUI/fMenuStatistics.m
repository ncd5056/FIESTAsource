function fMenuStatistics(func,varargin)
switch func
    case 'MSD'
        MSD;
    case 'AverageFilament'
        AverageFilament;   
end


function AverageFilament
global Filament;
Selected = [Filament.Selected];
if max(Selected)==0
    fMsgDlg('No Filaments selected!','error');
    return;
end
for m = find(Selected)
    nFrames = size(Filament(m).Results,1);
    nData = zeros(1,nFrames);
    for n =1:nFrames
        nData(n)=size(Filament(m).Data{n},1);
    end
    X = zeros(max(nData),nFrames);
    Y = zeros(max(nData),nFrames);
    D = zeros(max(nData),nFrames);
    W = zeros(max(nData),nFrames);
    H = zeros(max(nData),nFrames);
    B = zeros(max(nData),nFrames);
    %create average filament
    if min(nData)~=max(nData)
        %number of pixel positions per frame is different
        for n =1:nFrames
            if nData(n)~=max(nData);
                %interpolated to get the same number of pixel positions per frame
                new_vector = 1:(2*nData(n)-max(nData))/nData(n):nData(n);
                old_vector = 1:nData(n);
                X(:,n) = interp1(old_vector,Filament(m).Data{n}(:,1),new_vector);
                Y(:,n) = interp1(old_vector,Filament(m).Data{n}(:,2),new_vector);
                D(:,n) = interp1(old_vector,Filament(m).Data{n}(:,3),new_vector);
                W(:,n) = interp1(old_vector,Filament(m).Data{n}(:,4),new_vector);
                H(:,n) = interp1(old_vector,Filament(m).Data{n}(:,5),new_vector);
                B(:,n) = interp1(old_vector,Filament(m).Data{n}(:,6),new_vector);   
            else
                X(:,n) = Filament(m).Data{n}(:,1);
                Y(:,n) = Filament(m).Data{n}(:,2);
                D(:,n) = Filament(m).Data{n}(:,3);
                W(:,n) = Filament(m).Data{n}(:,4);
                H(:,n) = Filament(m).Data{n}(:,5);
                B(:,n) = Filament(m).Data{n}(:,6);
            end
        end
    else
        %number of pixel positions per frame is the same
        for n =1:nFrames
            X(:,n) = Filament(m).Data{n}(:,1);
            Y(:,n) = Filament(m).Data{n}(:,2);
            D(:,n) = Filament(m).Data{n}(:,3);
            W(:,n) = Filament(m).Data{n}(:,4);
            H(:,n) = Filament(m).Data{n}(:,5);
            B(:,n) = Filament(m).Data{n}(:,6);
        end
    end
    %average the filament pixel positions over all frames
    Filament(m).Data{1} = [mean(X,2) mean(Y,2) mean(D,2) mean(W,2) mean(H,2) mean(B,2)];  
    Filament(m).Data(2:end)=[];
    Filament(m).Results(2:end,:)=[];
    Filament(m).PosStart(2:end,:)=[];
    Filament(m).PosCenter(2:end,:)=[];
    Filament(m).PosEnd(2:end,:)=[];
    if ~isempty(Filament(m).PathData)
        Filament(m).PathData(2:end,:)=[];
    end
end

function [sd,tau] = CalcSD(Results,Dis,sd,tau)
%get frame numbers, time, X/Y position
F=Results(:,1);
T=Results(:,2);
X=Results(:,3);
Y=Results(:,4);    
%calculate square displacment and time difference with interpolated data
min_frame=min(F);
max_frame=max(F);
for k=1:fix(log2(max_frame-min_frame))
    if length(sd)<k
        %create cell for sd and tau if not existing
        sd{k}=[];
        tau{k}=[];
    end
    n=1;
    while F(n)+2^(k-1)<max_frame
        %check if datapoint was tracked 
        num_frame = find(F(n)+2^(k-1) == F, 1);
        if ~isempty(num_frame)
           %calculate square displacment
            if ~isempty(Dis) %1D
                sd{k}=[sd{k} ((Dis(num_frame)-Dis(n))/1000)^2];
            else %2D
                sd{k}=[sd{k} ((X(num_frame)-X(n))/1000)^2 + ((Y(num_frame)-Y(n))/1000)^2];
            end
            %calculate time difference
            tau{k}=[tau{k} T(num_frame)-T(n)];                
            n=num_frame;
        else
            n=n+1;
        end
    end
end

function MSD
global Molecule
global Filament
%check whether to use 1D or 2D mean square displacement
if isempty(Molecule) && isempty(Filament)
    return;
end
Selected = [ [Molecule.Selected] [Filament.Selected]];
if max(Selected)==0
    fMsgDlg('No Track selected!','error');
    return;
end
Mode =  fQuestDlg({'Do you want to calculate the','mean square displacement for all','selected tracks in one dimension or two?'},'Mean Square Displacement',{'1D','2D','Cancel'},'1D');
if ~strcmp(Mode,'Cancel') && ~isempty(Mode)
    %define variable for square displacment and time difference
    sd=[];
    tau=[];
    if ~isempty(Molecule)
        %for every selected molecule
        for n = find([Molecule.Selected]==1)
            if strcmp(Mode,'2D')
                Dis = []; 
            else
                if ~isempty(Molecule(n).PathData)
                    Dis = Molecule(n).PathData(:,3);
                else
                    fMsgDlg({'Some tracks have no path present.','Use ''Path Statistics'' to get path.'},'error');
                    return;
                end
            end
            [sd,tau] = CalcSD(Molecule(n).Results,Dis,sd,tau);
        end
    end
    if ~isempty(Filament)
        %for every selected filament
        for n = find([Filament.Selected]==1)
            if strcmp(Mode,'2D')
                Dis = []; 
            else
                if ~isempty(Filament(n).PathData)
                    Dis = Filament(n).PathData(:,3);
                else
                    fMsgDlg({'Some tracks have no path present.','Use ''Path Statistics'' to get path.'},'error');
                    return;
                end
            end
            %calculate square displacement
            [sd,tau] = CalcSD(Filament(n).Results,Dis,sd,tau);
        end
    end
    for m=1:length(sd)
        TimeVsMSD(m,1)=mean(tau{m});
        TimeVsMSD(m,2)=mean(sd{m});
        TimeVsMSD(m,3)=std(sd{m})/sqrt(length(sd{m}));
        TimeVsMSD(m,4)=length(sd{m});
    end
    [FileName, PathName, FilterIndex] = uiputfile({'*.mat','MAT-file (*.mat)';'*.txt','TXT-File (*.txt)'},'Save FIESTA Mean Square Displacement',fShared('GetSaveDir'));
    file = [PathName FileName];
    if FilterIndex==1
        fShared('SetSaveDir',PathName);
        if isempty(findstr('.mat',file))
            file = [file '.mat'];
        end
        save(file,'TimeVsMSD');
    elseif FilterIndex==2
        fShared('SetSaveDir',PathName);
        if isempty(findstr('.txt',file))
            file = [file '.txt'];
        end
        f = fopen(file,'w');
        fprintf(f,'Time[s]\tMSD[µm²]\tError(mean)\tN\n');
        fprintf(f,'%f\t%f\t%f\t%f\n',TimeVsMSD');
        fclose(f);
    end
end