function myoutput = posterior_sampler_core(myinputs,fblck,nblck,whoiam,ThisMatlab)
% function myoutput = posterior_sampler_core(myinputs,fblck,nblck,whoiam, ThisMatlab)
% Contains the most computationally intensive portion of code in
% posterior_sampler (the 'for xxx = fblck:nblck' loop). The branches in  that 'for'
% cycle are completely independent to be suitable for parallel execution.
%
% INPUTS
%   o myimput            [struc]     The mandatory variables for local/remote
%                                    parallel computing obtained from posterior_sampler.m
%                                    function.
%   o fblck and nblck    [integer]   The Metropolis-Hastings chains.
%   o whoiam             [integer]   In concurrent programming a modality to refer to the different threads running in parallel is needed.
%                                    The integer whoiam is the integer that
%                                    allows us to distinguish between them. Then it is the index number of this CPU among all CPUs in the
%                                    cluster.
%   o ThisMatlab         [integer]   Allows us to distinguish between the
%                                    'main' Matlab, the slave Matlab worker, local Matlab, remote Matlab,
%                                     ... Then it is the index number of this slave machine in the cluster.
% OUTPUTS
%   o myoutput  [struc]
%               If executed without parallel, this is the original output of 'for b =
%               fblck:nblck'. Otherwise, it's a portion of it computed on a specific core or
%               remote machine. In this case:
%                               record;
%                               irun;
%                               NewFile;
%                               OutputFileName
%
% ALGORITHM
%   Portion of Posterior Sampler.
%
% SPECIAL REQUIREMENTS.
%   None.
%
% PARALLEL CONTEXT
% See the comments in the posterior_sampler.m funtion.


% Copyright © 2006-2023 Dynare Team
%
% This file is part of Dynare.
%
% Dynare is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% Dynare is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with Dynare.  If not, see <https://www.gnu.org/licenses/>.

if nargin<4
    whoiam=0;
end

% reshape 'myinputs' for local computation.
% In order to avoid confusion in the name space, the instruction struct2local(myinputs) is replaced by:

TargetFun=myinputs.TargetFun;
ProposalFun=myinputs.ProposalFun;
xparam1=myinputs.xparam1;
mh_bounds=myinputs.mh_bounds;
last_draw=myinputs.ix2;
last_posterior=myinputs.ilogpo2;
fline=myinputs.fline;
npar=myinputs.npar;
nruns=myinputs.nruns;
NewFile=myinputs.NewFile;
MAX_nruns=myinputs.MAX_nruns;
sampler_options=myinputs.sampler_options;
d=myinputs.d;
InitSizeArray=myinputs.InitSizeArray;
record=myinputs.record;
dataset_ = myinputs.dataset_;
dataset_info = myinputs.dataset_info;
bayestopt_ = myinputs.bayestopt_;
estim_params_ = myinputs.estim_params_;
options_ = myinputs.options_;
M_ = myinputs.M_;
dr = myinputs.dr;
endo_steady_state = myinputs.endo_steady_state;
exo_steady_state=myinputs.exo_steady_state;
exo_det_steady_state=myinputs.exo_det_steady_state;

MetropolisFolder = CheckPath('metropolis',M_.dname);
ModelName = M_.fname;
BaseName = [MetropolisFolder filesep ModelName];
save_tmp_file = sampler_options.save_tmp_file;

OpenOldFile = ones(nblck,1);
if strcmpi(ProposalFun,'rand_multivariate_normal')
    sampler_options.n = npar;
    sampler_options.ProposalDensity = 'multivariate_normal_pdf';
elseif strcmpi(ProposalFun,'rand_multivariate_student')
    sampler_options.n = sampler_options.student_degrees_of_freedom;
    sampler_options.ProposalDensity = 'multivariate_student_pdf';
end

%
% Now I run the (nblck-fblck+1) MCMC chains
%

sampler_options.xparam1 = xparam1;
if ~isempty(d)
    sampler_options.proposal_covariance_Cholesky_decomposition = d*diag(bayestopt_.jscale);
    %store information for load_mh_file
    record.ProposalCovariance=d;
    record.ProposalScaleVec=bayestopt_.jscale;
end

if ~isoctave && ~isempty(gcp('nocreate'))
    % Parallel pool detected in MATLAB, MCMC can be run in parallel
    p = gcp;

    if isa(p, 'Parallel.Threadpool')
        error('dynare:estimation:posterior_sampler_core:threadsnotallowd', 'Thread pools are not compatible with MCMC, please start a Process pool')
    end

    % Do some naive checks on the parallel setup to inform the user of
    % possible better options
    if (p.NumWorkers > options_.mh_nblck)
        % Check if too many workers open
        warning('dynare:posterior_sampler_core:toomanyworkers', ...
            'Your parallel setup might be inefficient, you are using %d Workers, but you only have %d blocks, please consider using less workers and optionally more threads:\n\nc = parcluster(''%s'');\nc.NumThreads = <NumThreads>;\nparpool(c,%d);\n', p.NumWorkers, options_.mh_nblck, p.Cluster.Profile, options_.mh_nblck)
    elseif p.NumThreads == 1 && p.NumWorkers*2 <= p.Cluster.NumWorkers
        % Check if we could hyperthread workers
        warning('dynare:posterior_sampler_core:singlethreaded', ...
            'The number of Threads in your parallel pool is 1, but you might have available compute capabilities. Consider increasing the ThreadNumber such that NumWorkers*NumThreads is equal to num cores in your machine\n\nc = parcluster(''%s'');\nc.NumThreads = <NumThreads>;\nparpool(c,<NumWorkers>);\n', p.Cluster.Profile)
    end

    % Preallocate Futures
    F(1:options_.mh_nblck) = parallel.Future;

    % Create waitbars and queue
    q = parallel.pool.DataQueue;
    afterEach(q, @(task) UpdateBar(task, sampler_options, options_))
    refresh_rate = sampler_options.parallel_bar_refresh_rate;

    % Close all multiwaitbars (if any) and ensure cleanup
    dynutil.multiWaitbar('CloseAll');
    cleanupObj = onCleanup(@() dynutil.multiWaitbar('CloseAll'));

    % Launch parallel Jobs    
    block_iter = 0;
    for curr_block = fblck:nblck

        block_iter = block_iter+1;
        
        % Submit current block to a worker. Use parfeval instead of parfor
        % to allow keeping all the mh recovery options.
        F(block_iter) = parfeval(p, @computeMHBlock, 9, ...
            curr_block, ...            
            options_, ...
            record.InitialSeeds(curr_block), ...
            BaseName, ...
            OpenOldFile(curr_block) , ...
            NewFile(curr_block), ...
            InitSizeArray(curr_block), ...
            last_draw(curr_block, :), ...
            last_posterior(curr_block), ...
            TargetFun, ...
            mh_bounds, ...
            dataset_, ...
            fline(curr_block), ...
            npar, ...
            nruns(curr_block), ...
            MAX_nruns, ...
            sampler_options, ...
            dataset_info, ...
            bayestopt_, ...
            estim_params_, ...
            M_, ...
            dr, ...
            endo_steady_state, ...
            exo_steady_state, ...
            exo_det_steady_state, ...
            save_tmp_file, ...
            MetropolisFolder, ...
            ModelName, ...
            refresh_rate, ...
            true, ...
            q);
        
    end

    % Retrieve the results in finishing order (not necessarily the same as
    % submission)
    indices = fblck:nblck;
    for idx = 1 : numel(F)

        % Retrieve next finished block
        [block_iter, accepted_draws_this_chain, feval_this_chain, draw_iter, ...
            LastSeeds, OutputFileName, LastParameters, LastLogPost, ...
            draw_index_current_file_i, NewFile] = fetchNext(F);

        curr_block = indices(block_iter);

        % Store the results
        record.LastParameters(curr_block,:) = LastParameters;
        record.LastLogPost(curr_block) = LastLogPost;

        record.AcceptanceRatio(curr_block) = accepted_draws_this_chain/(draw_iter-1);
        record.FunctionEvalPerIteration(curr_block) = feval_this_chain/(draw_iter-1);
        record.LastSeeds(curr_block).Unifor = LastSeeds.Unifor;
        record.LastSeeds(curr_block).Normal = LastSeeds.Normal;

        NewFile(curr_block) = NewFile;
        OutputFileName(block_iter,:) = OutputFileName;

        if curr_block == nblck
            draw_index_current_file = draw_index_current_file_i;
        end

        % Remove waitbar
        dynutil.multiWaitbar(['Chain', int2str(curr_block)], 'Close');

    end % End of the loop over the mh-blocks.
   
else % Run in serial as usual

    block_iter=0;

    for curr_block = fblck:nblck

        block_iter=block_iter+1;

        % Prepare waiting bars
        Label = ['%s (' int2str(curr_block) '/' int2str(options_.mh_nblck) ')%s'];
        if whoiam
            refresh_rate = sampler_options.parallel_bar_refresh_rate;
            bar_title = sampler_options.parallel_bar_title;
            prc0=(curr_block-fblck)/(nblck-fblck+1)*(isoctave() || options_.console_mode)+(draw_iter-1)/nruns_cb;
            hh_fig = dyn_waitbar({prc0,whoiam,options_.parallel(ThisMatlab)},sprintf(Label,bar_title, '...'));
        else
            refresh_rate = sampler_options.serial_bar_refresh_rate;
            bar_title = sampler_options.serial_bar_title;
            hh_fig = dyn_waitbar(0,sprintf(Label,bar_title, '...'));
            set(hh_fig,'Name',bar_title);
        end
        hh_fig.UserData = sprintf(Label,bar_title, ' %s');

        % Compute Block
        [accepted_draws_this_chain, feval_this_chain, draw_iter, ...
            LastSeeds, OutputFileName_cb, LastParameters, LastLogPost, ...
            draw_index_current_file_i, NewFile_cb] = computeMHBlock( ...
            curr_block, ...           
            options_, ...
            record.InitialSeeds(curr_block), ...
            BaseName, ...
            OpenOldFile(curr_block), ...
            NewFile(curr_block), ...
            InitSizeArray(curr_block), ...
            last_draw(curr_block,:), ...
            last_posterior(curr_block), ...
            TargetFun, ...
            mh_bounds, ...
            dataset_, ...
            fline(curr_block), ...
            npar, ...
            nruns(curr_block), ...
            MAX_nruns, ...
            sampler_options, ...
            dataset_info, ...
            bayestopt_, ...
            estim_params_, ...
            M_, ...
            dr, ...
            endo_steady_state, ...
            exo_steady_state, ...
            exo_det_steady_state, ...
            save_tmp_file, ...
            MetropolisFolder, ...
            ModelName, ...
            refresh_rate, ...
            false, ...
            hh_fig);

        % Reconcile
        record.LastParameters(curr_block,:) = LastParameters;
        record.LastLogPost(curr_block) = LastLogPost;

        record.AcceptanceRatio(curr_block) = accepted_draws_this_chain/(draw_iter-1);
        record.FunctionEvalPerIteration(curr_block) = feval_this_chain/(draw_iter-1);
        record.LastSeeds(curr_block).Unifor = LastSeeds.Unifor;
        record.LastSeeds(curr_block).Normal = LastSeeds.Normal;

        NewFile(curr_block) = NewFile_cb;
        OutputFileName(block_iter,:) = OutputFileName_cb; %#ok<AGROW>

        if curr_block == nblck
            draw_index_current_file = draw_index_current_file_i;
        end

        dyn_waitbar_close(hh_fig);

    end % End of the loop over the mh-blocks.

end

myoutput.record = record;
myoutput.irun = draw_index_current_file;
myoutput.NewFile = NewFile;
myoutput.OutputFileName = OutputFileName;

end

function [accepted_draws_this_chain, feval_this_chain, draw_iter, ...
    LastSeeds_cb, OutputFileName, LastParameters_cb, LastLogPost_cb, ...
    draw_index_current_file, NewFile_cb, InitSizeArray_cb] = computeMHBlock(curr_block, options_, InitialSeeds_cb, BaseName, OpenOldFile_cb, NewFile_cb, ...
    InitSizeArray_cb, last_draw_cb, last_posterior_cb, TargetFun, mh_bounds,dataset_, fline_cb, npar, nruns_cb, MAX_nruns, sampler_options, dataset_info, bayestopt_, estim_params_, ...
    M_, dr, endo_steady_state, exo_steady_state, exo_det_steady_state,save_tmp_file, MetropolisFolder, ModelName, refresh_rate, UseParallel, q)
%COMPUTEMHBlOCK do the calculation of each block. The logic of the waitbar
%is different depending on whether we are in serial or using pstools versus
%using the parallel computing toolbox
%
% Inputs
%   - See parent function for most of them
%   - UseParallel (true/false) whether to use Parallel Computing Toolbox or
%   not
%   - q either the queue or the dyn_waitbar figure

curr_block_str = int2str(curr_block);

LastSeeds=[];

if UseParallel
    send(q, struct('Initialize', true, 'Block', curr_block_str))    
end

try
    % This will not work if the master uses a random number generator not
    % available in the slave (different Matlab version or
    % Matlab/Octave cluster). Therefore the trap.
    %
    % Set the random number generator type (the seed is useless but needed by the function)
    if ~isoctave
        options_=set_dynare_seed_local_options(options_,options_.DynareRandomStreams.algo, options_.DynareRandomStreams.seed);
    else
        options_=set_dynare_seed_local_options(options_,options_.DynareRandomStreams.seed+curr_block);
    end
    % Set the state of the RNG
    set_dynare_random_generator_state(InitialSeeds_cb.Unifor, InitialSeeds_cb.Normal);
catch
    % If the state set by master is incompatible with the slave, we only reseed
    options_=set_dynare_seed_local_options(options_,options_.DynareRandomStreams.seed+curr_block);
end
mh_recover_flag=0;
if options_.mh_recover && exist([BaseName '_mh_tmp_blck' curr_block_str '.mat'],'file')==2 && OpenOldFile_cb
    % this should be done whatever value of load_mh_file
    load([BaseName '_mh_tmp_blck' curr_block_str '.mat']);
    draw_iter = size(neval_this_chain,2)+1; %#ok<NODEF>
    draw_index_current_file = draw_iter+fline_cb-1;
    feval_this_chain = sum(sum(neval_this_chain));
    feval_this_file = sum(sum(neval_this_chain));
    if feval_this_chain>draw_index_current_file-fline_cb
        % non Metropolis type of sampler
        accepted_draws_this_chain = draw_index_current_file-fline_cb;
        accepted_draws_this_file = draw_index_current_file-fline_cb;
    else
        accepted_draws_this_chain = 0;
        accepted_draws_this_file = 0;
    end
    mh_recover_flag=1;
    set_dynare_random_generator_state(LastSeeds.(['file' int2str(NewFile_cb)]).Unifor, LastSeeds.(['file' int2str(NewFile_cb)]).Normal);
    last_draw_cb=x2(draw_index_current_file-1,:);
    last_posterior_cb=logpo2(draw_index_current_file-1);
    OpenOldFile_cb = 0;
else
    if (options_.load_mh_file~=0) && (fline_cb>1) && OpenOldFile_cb %load previous draws and likelihood
        load([BaseName '_mh' int2str(NewFile_cb) '_blck' curr_block_str '.mat'])
        x2 = [x2;zeros(InitSizeArray_cb-fline_cb+1,npar)];
        logpo2 = [logpo2;zeros(InitSizeArray_cb-fline_cb+1,1)];
        OpenOldFile_cb = 0;
    else

        x2 = zeros(InitSizeArray_cb,npar);
        logpo2 = zeros(InitSizeArray_cb,1);
    end
end
if mh_recover_flag==0
    accepted_draws_this_chain = 0;
    accepted_draws_this_file = 0;
    feval_this_chain = 0;
    feval_this_file = 0;
    draw_iter = 1;
    draw_index_current_file = fline_cb; %get location of first draw in current block
end

sampler_options.curr_block = curr_block;
while draw_iter <= nruns_cb

    [par, logpost, accepted, neval] = posterior_sampler_iteration(TargetFun, last_draw_cb, last_posterior_cb, sampler_options,dataset_,dataset_info,options_,M_,estim_params_,bayestopt_,mh_bounds,dr, endo_steady_state, exo_steady_state, exo_det_steady_state);

    x2(draw_index_current_file,:) = par;
    last_draw_cb = par;
    logpo2(draw_index_current_file) = logpost;
    last_posterior_cb = logpost;
    neval_this_chain(:, draw_iter) = neval;
    feval_this_chain = feval_this_chain + sum(neval);
    feval_this_file = feval_this_file + sum(neval);
    accepted_draws_this_chain = accepted_draws_this_chain + accepted;
    accepted_draws_this_file = accepted_draws_this_file + accepted;

    prtfrc = draw_iter/nruns_cb;
    if mod(draw_iter, refresh_rate)==0
        if accepted_draws_this_chain/draw_iter==1 && sum(neval)>1
            txt = sprintf('Function eval per draw %4.3f', feval_this_chain/draw_iter);
        else
            txt = sprintf('Current acceptance ratio %4.3f', accepted_draws_this_chain/draw_iter);
        end

        if UseParallel
            send(q, struct('Initialize', false, 'Block', curr_block_str, 'Text', txt, 'Value', prtfrc))
        else
            dyn_waitbar(prtfrc, q, sprintf(q.UserData, txt));
        end

        if save_tmp_file
            [LastSeeds.(['file' int2str(NewFile_cb)]).Unifor, LastSeeds.(['file' int2str(NewFile_cb)]).Normal] = get_dynare_random_generator_state();
            save([BaseName '_mh_tmp_blck' curr_block_str '.mat'],'x2','logpo2','LastSeeds','neval_this_chain','accepted_draws_this_chain','accepted_draws_this_file','feval_this_chain','feval_this_file');
        end
    end
    if (draw_index_current_file == InitSizeArray_cb) || (draw_iter == nruns_cb) % Now I save the simulations, either because the current file is full or the chain is done
        [LastSeeds.(['file' int2str(NewFile_cb)]).Unifor, LastSeeds.(['file' int2str(NewFile_cb)]).Normal] = get_dynare_random_generator_state();
        if save_tmp_file
            delete([BaseName '_mh_tmp_blck' curr_block_str '.mat']);
        end
        save([BaseName '_mh' int2str(NewFile_cb) '_blck' curr_block_str '.mat'],'x2','logpo2','LastSeeds','accepted_draws_this_chain','accepted_draws_this_file','feval_this_chain','feval_this_file');
        fidlog = fopen([MetropolisFolder '/metropolis.log'],'a');
        fprintf(fidlog,'\n');
        fprintf(fidlog,['%% Mh' int2str(NewFile_cb) 'Blck' curr_block_str ' (' datestr(now,0) ')\n']);
        fprintf(fidlog,' \n');
        fprintf(fidlog,['  Number of simulations.: ' int2str(length(logpo2)) '\n']);
        fprintf(fidlog,['  Acceptance ratio......: ' num2str(accepted_draws_this_file/length(logpo2)) '\n']);
        fprintf(fidlog,['  Feval per iteration...: ' num2str(feval_this_file/length(logpo2)) '\n']);
        fprintf(fidlog,'  Posterior mean........:\n');
        for i=1:length(x2(1,:))
            fprintf(fidlog,['    params:' int2str(i) ': ' num2str(mean(x2(:,i))) '\n']);
        end
        fprintf(fidlog,['    log2po:' num2str(mean(logpo2)) '\n']);
        fprintf(fidlog,'  Minimum value.........:\n');
        for i=1:length(x2(1,:))
            fprintf(fidlog,['    params:' int2str(i) ': ' num2str(min(x2(:,i))) '\n']);
        end
        fprintf(fidlog,['    log2po:' num2str(min(logpo2)) '\n']);
        fprintf(fidlog,'  Maximum value.........:\n');
        for i=1:length(x2(1,:))
            fprintf(fidlog,['    params:' int2str(i) ': ' num2str(max(x2(:,i))) '\n']);
        end
        fprintf(fidlog,['    log2po:' num2str(max(logpo2)) '\n']);
        fprintf(fidlog,' \n');
        fclose(fidlog);
        accepted_draws_this_file = 0;
        feval_this_file = 0;
        if draw_iter == nruns_cb % I record the last draw...
            LastParameters_cb = x2(end,:);
            LastLogPost_cb = logpo2(end);
        end
        % size of next file in chain curr_block
        InitSizeArray_cb = min(nruns_cb-draw_iter,MAX_nruns);
        % initialization of next file if necessary
        if InitSizeArray_cb
            x2 = zeros(InitSizeArray_cb,npar);
            logpo2 = zeros(InitSizeArray_cb,1);
            NewFile_cb = NewFile_cb + 1;
            draw_index_current_file = 0;
        end
    end
    draw_iter=draw_iter+1;
    draw_index_current_file = draw_index_current_file + 1;
end % End of the simulations for one mh-block.

if nruns_cb
    [LastSeeds_cb.Unifor, LastSeeds_cb.Normal] = get_dynare_random_generator_state();
end
OutputFileName = {[MetropolisFolder,filesep], [ModelName '_mh*_blck' curr_block_str '.mat']};

end

function UpdateBar(task, sampler_options, options_)
bar_title = sampler_options.parallel_bar_title;
LabelBase = [bar_title ' ('  task.Block '/' int2str(options_.mh_nblck) ')'];
Name = ['Chain', task.Block];
if task.Initialize    
    dynutil.multiWaitbar(Name, 0, 'Color', 'b', 'Relabel', [LabelBase, '...'], 'CanCancel', 'on', 'CancelFcn', @(s,e) cancelAllFutures());
else
    dynutil.multiWaitbar(Name, task.Value, 'Relabel', [LabelBase, ' ', task.Text]);
end
end

function cancelAllFutures()

F = gcp().FevalQueue;
if ~isempty(F.QueuedFutures)
    cancel(F.QueuedFutures);
end
cancel(F.RunningFutures);

end