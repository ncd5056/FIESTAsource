function [Queue,Status]=fGetServerQueue
DirServer = fShared('CheckServer');
Queue=[];
Status=[];
if ~isempty(DirServer);
    for n=1:2
        files=dir([DirServer 'Queue' filesep 'Job' num2str(n) filesep 'FiestaQueue*.mat']);
        if ~isempty(files)
            addQueue = fLoad([DirServer 'Queue' filesep 'Job' num2str(n) filesep files(1).name],'ServerQueue');
            try
                addStatus = load([DirServer 'Queue' filesep 'Job' num2str(n) filesep 'FiestaStatus.mat']);
                addStatus.JobNr = n;
            catch ME
                Status = [];
            end
            Queue = [Queue addQueue];
            Status = [Status addStatus];
        end
    end
    files=dir([DirServer 'Queue' filesep 'FiestaQueue*.mat']);
    if ~isempty(files)
        for n=1:length(files)
            addQueue=fLoad([DirServer 'Queue' filesep files(n).name],'ServerQueue');
            Queue = [Queue addQueue];
        end
    end
end