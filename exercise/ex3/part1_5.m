%% EXERCISE X - PART X
clc
% close all
clear all

% paths
addpath(genpath('files/TASK1'))
addpath('functions')
addpath('data')
addpath([matlabroot, '/toolbox/ann_wrapper'])   % change to ann_wrapper path

if exist('ann') ~= 2
    error('cannot find ann. check the ann_wrapper path')
end

% data parameters
off_files = {'bun', 'bunny', 'bunny2', 'cat'};

% parameters
max_iter = 5;
threshold = 1e-4;

% rimls parameters
sigma_r = 0.5;    % parameter for RIMLS (DO NOT CHANGE!)
sigma_n = {0.5};  % parameter for RIMLS (sharpness)

% debug
debug = false;

%% PART 1-5
disp('===================================================================')
disp('PART 1-5')

for file_idx = 1:size(off_files, 2)
    %% DATA LOAD
    file = off_files{file_idx};
    
    disp('-------------------------------------------------------------------')
    disp(['off file loading: ', file, '.off'])
    
    %  V  #V by 3 list of vertices
    %  F  #F by 3 list of triangle indices
    %  N  #V by 3 list of normals
    
    [V_file,F_file,~,~,~] = readOFF([file, '.off']);
    N_file = per_vertex_normals(V_file,F_file);
    
    %% CALCULATE NEW V FOR RIMLS
    disp('calculating new V matrix using RIMLS...')
    
    for i=1:size(sigma_n, 2)
        
        sigma_n_i = sigma_n{i};
        
        V = V_file;
        FxGradFx = zeros(size(V));
        
        tic
        for j=1:max_iter
            
            % calculate V_next: v_next = v - f(x) grad f(x)
            FxGradFx = FxGradFx3D_RIMLS(V, V_file, N_file, sigma_r, sigma_n_i, debug);
            
            % V update
            V = V - FxGradFx;
            
            if norm(FxGradFx) < threshold
                % converged
                break
            end
        end
        t = toc;
        
        % log running time
        disp(['RIMLS running time = ', num2str(t)])
        
        % saving file
        filename = [file, '_RIMLS.off'];
        disp(['off file saving: ', filename])
        
        N = per_vertex_normals(V,F_file);
        writeOFF(filename, V, F_file, [], [], N);
        
    end
end