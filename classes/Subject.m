classdef Subject < handle
    properties
        Name
        Recordings
        CorrelationThreshold
        Modelblink
        AmplitudeScale = 1
        BlinkLength = 250000
        ModelSubsamplingRate = 100
        ActivityDecayConstant = 50000
        AverageTrackingError = 0
        Parent
    end

    methods
        function obj = Subject(name, corrthreshold, parent)
            obj.Name = name;
            obj.CorrelationThreshold = corrthreshold;
            obj.Modelblink = Modelblink();
            obj.Parent = parent;
            disp(['created subject ', name])
        end

        function obj = addrecording(obj, number, eventStream, isTrainingRecording, varargin)
            obj.Recordings{1,number} = Recording(number, eventStream, isTrainingRecording, obj);
            if nargin > 4
                obj.Recordings{1,number}.NumberOfBlinks = varargin{1};
            end
        end
        
        function training = gettrainingrecordingindex(obj)
            training = 0;
            for index = 1:numel(obj.Recordings)
                if ~isempty(obj.Recordings{index}) && obj.Recordings{index}.IsTrainingRecording
                    training = index;
                    break
                end
            end
        end
        
        function recording = gettrainingrecording(obj)
            recording = obj.Recordings{obj.gettrainingrecordingindex};
        end
        
        function shiftallannotatedblinksby(obj, shift)
            r = obj.gettrainingrecording;
            loc = r.getannotatedlocations;
            for i = 1:length(loc)
                r.(loc{i}).Times = r.(loc{i}).Times + shift;
                disp(['new times for ', loc{i}, ': ', num2str(r.(loc{i}).Times)])
            end
        end
        
        function calculateallcorrelations(obj)
            if obj.gettrainingrecordingindex ~= 0
                for r = 1:numel(obj.Recordings)
                    if ~isempty(obj.Recordings{r})
                        disp(['Subject: ', obj.Name, ', recording no: ', num2str(r)])
                        obj.Recordings{r}.calculatecorrelation();
                    end
                end
            end
        end
        
        function detectallblinks(obj)
            if obj.gettrainingrecordingindex ~= 0
                for r = 1:numel(obj.Recordings)
                    if ~isempty(obj.Recordings{r})
                        disp(['Subject: ', obj.Name, ', recording no: ', num2str(r)])
                        obj.Recordings{r}.detectblinks();
                    end
                end
            end
        end
        
        function calculatealltrackings(obj)
            if obj.gettrainingrecordingindex ~= 0
                for r = 1:numel(obj.Recordings)
                    if ~isempty(obj.Recordings{r})
                        obj.Recordings{r}.calculatetracking;
                    end
                end
            end
        end
        
        function average = calculateaverageerror(obj)
            average = 0;
            num = 0;
            for r = 1:numel(obj.Recordings)
                if obj.Recordings{r}.calculatetrackingerror
                    average = average + obj.Recordings{r}.AverageTrackingError;
                    num = num + 1;
                end
            end
            average = average / num;
            obj.AverageTrackingError = average;
            disp(['average tracking error for subject ', obj.Name, ': ', num2str(obj.AverageTrackingError)])
        end
        
        function exportmodelblink(obj)
            path = ['/home/gregorlenz/Recordings/face-detection/', obj.Parent.DatasetType, '/', obj.Name, '/modelblink.csv'];
            m = [obj.Modelblink.AverageOn; obj.Modelblink.AverageOff];
            csvwrite(path, m);
        end
        
        function ploteyeactivitiesfortraining(obj)
            rec = obj.gettrainingrecording;
            locs = rec.getannotatedlocations;
            figure
            for l = 1:numel(locs)
                rec.(locs{l}).plotactivity(numel(locs), 1, l, locs{l})
            end
        end
        
        function plotallcorrelations(obj)
            figure
            for r = 1:numel(obj.Recordings)
                if ~isempty(obj.Recordings{r})
                    ax = subplot(1,length(obj.Recordings), r);
                    obj.Recordings{r}.plotcorrelation(ax);
                end
            end
        end
        
        function plotalldetectedblinks(obj)
            obj.detectallblinks;
            figure
            for r = 1:numel(obj.Recordings)
                if ~isempty(obj.Recordings{r})
                    ax = subplot(1,length(obj.Recordings), r);
                    obj.Recordings{r}.plotdetectedblinks(ax);
                end
            end
        end
        
        function plotalltrackings(obj)
            figure
            for r = 1:numel(obj.Recordings)
                if ~isempty(obj.Recordings{r})
                    ax = subplot(1,length(obj.Recordings), r);
                    obj.Recordings{r}.plottracking(ax);
                end
            end
        end
        
        function adjustmodelblink(obj)
            figure
            hold on
            r = obj.gettrainingrecordingindex;

            changedSomething = 0;
            difference = 1;
            iteration = 0;
            while (difference > 0)
                [blinksOn, blinksOff] = obj.Recordings{r}.getallblinks();
                locations = fieldnames(blinksOn);
                iteration = iteration + 1;
                difference = 0;
                for j = 1:length(locations)
                    for i = 2:size(blinksOn.(locations{j}),1) % start to correlate the second annotated blink with the first one
                        %a = plot(blinksOn.(locations{j})(i,:));
                        [xcOn, lagOn] = xcorr(blinksOn.(locations{j})(1,:), blinksOn.(locations{j})(i,:));
                        [~, indexOn] = max(abs(xcOn));
                        lagDiffOn = lagOn(indexOn);
                        [xcOff, lagOff] = xcorr(blinksOff.(locations{j})(1,:), blinksOff.(locations{j})(i,:));
                        [~, indexOff] = max(abs(xcOff));
                        lagDiffOff = lagOff(indexOff);
                        lagDiff = 0.6*lagDiffOn + 0.4*lagDiffOff;
                        if abs(lagDiff) > 1 %resembles accuracy of lagdiff * obj.ModelSubsamplingRate us
                            timestamp = obj.gettrainingrecording.(locations{j}).Times(i)-lagDiff*obj.ModelSubsamplingRate;
                            obj.Recordings{r}.(locations{j}).Times(i) = timestamp;
                            disp(['Adjusted timestamp for blink ', int2str(i), ' at ', locations{j}, ' is: ', int2str(timestamp)])
                            difference = difference + 1;
                            changedSomething = 1;
                        end
                        %a.Color = 'blue';
                        %b = plot(blinksOff.(locations{j})(i,:));
                        %b.Color = 'red';
                    end
                end
                if changedSomething
                    disp (['Iteration no. for locations: ', int2str(iteration)])
                end
            end
                        
            difference = 1; % no do...while loop in matlab exists
            iteration = 0;
            while (difference > 0)
                difference = 0;
                iteration = iteration + 1;
                for j = 1:length(locations)
                    [averageOnFirst, averageOffFirst] = obj.gettrainingrecording.(locations{1}).getaverages();
                    [averageOn, averageOff] = obj.gettrainingrecording.(locations{j}).getaverages();
                    [xcOn, lagOn] = xcorr(averageOnFirst, averageOn);
                    [~, indexOn] = max(abs(xcOn));
                    lagDiffOn = lagOn(indexOn);
                    [xcOff, lagOff] = xcorr(averageOffFirst, averageOff);
                    [~, indexOff] = max(abs(xcOff));
                    lagDiffOff = lagOff(indexOff);
                    lagDiff = (lagDiffOn + lagDiffOff)/2;
                    if abs(lagDiff) > 1
                        obj.Recordings{r}.(locations{j}).Times = obj.Recordings{r}.(locations{j}).Times - (lagDiff * obj.ModelSubsamplingRate)/10;
                        disp(['lag between ', locations{1}, ' and ', locations{j}, ' is ', int2str(lagDiff*obj.ModelSubsamplingRate), ' us'])
                        difference = difference + 1;
                        changedSomething = 1;
                    end
                end
                if changedSomething
                    disp (['Iteration no. between blinks: ', int2str(iteration)])
                end
            end
            ax = gca;
            obj.plotmodelblink(ax)
            if changedSomething
                for l = 1:length(locations)
                    disp(['New times for ', locations{l}, ':'])
                    obj.gettrainingrecording.(locations{l}).Times
                end
            else
                disp('Single blinks of the model seem to correlate well.')
            end
        end
        
        function plotmodelblink(obj, varargin)
            if isempty(obj.gettrainingrecording.getannotatedlocations())
                error('no blinks annotated')
            end
            if nargin > 1
                ax = varargin{1};
            else
                figure;
                ax = gca;
            end
             %plot both average and variance for ON and OFF
            title(ax, obj.Name)
            ax = shadedErrorBar(1:length(obj.Modelblink.AverageOn), obj.Modelblink.AverageOn, obj.Modelblink.VarianceOn, 'lineprops', '-r');
            ax.mainLine.LineWidth = 3;
            ax = shadedErrorBar(1:length(obj.Modelblink.AverageOff), obj.Modelblink.AverageOff, obj.Modelblink.VarianceOff, 'lineprops', '-b');
            ax.mainLine.LineWidth = 3;
            ylim([0 inf])
        end
        
        function plotmodelblinkwithallblinks(obj)
            locations = obj.gettrainingrecording.getannotatedlocations;
            if numel(locations) > 0 
                figure 
                ax = gca;
            else
                error('not enough locations')
            end
            for l = 1:numel(locations)
                obj.gettrainingrecording.(locations{l}).plotblinks(ax)
            end
            obj.plotmodelblink(ax)
        end
    end
    
end