clc
close all
clear all

% parameters
threshold = 3;  % 3 px

% debug
debug = true;

%% DATA LOAD
addpath('data');
load('data/ListInputPoints.mat', 'ListInputPoints');

% correspondences
p_left = ListInputPoints(:, 1:2);
p_right = ListInputPoints(:, 3:4);

n = size(p_left, 1);

% images
img_left = imread('data/InputLeftImage.png');
img_right = imread('data/InputRightImage.png');

[img_left_h, img_left_w, ~] = size(img_left);
[img_right_h, img_right_w, ~] = size(img_right);

%% VISUALIZE CORRESPONDENCE
padding = 10;   % black padding
img = [img_left, zeros(img_left_h, padding, 3), img_right];

pt_l = p_left;
pt_r = p_right + [img_left_w, 0] + [padding, 0];

figure(1)
imshow(img);
hold on
line([pt_l(:,1)'; pt_r(:,1)'], [pt_l(:,2)'; pt_r(:,2)'], 'Color', 'blue');
hold off

%% DEFINE P0  
% make P0 problem
P0 = NewProblem([-img_left_w, -img_left_h], [img_left_w, img_left_h]);

% solve P0 problem
P0 = SolveWithLP(p_left, p_right, P0, threshold);

% list of problems (stack);
problem_stack = zeros(1, 0);
problem_stack = PushToStack(problem_stack, P0);

% upper and lower bound found by iteration
optimal_solution = [inf -inf];

% record update history (optimal_solution, iteration_solution)
if debug 
    optimal_solution_history = [inf, -inf, inf, -inf];
else 
    optimal_solution_history = [inf, -inf];
end

%% BRANCH AND BOUND (WITH DFS)

% finding global optimal solution! 
% i.e. iteration until empty stack, not convergence

while(size(problem_stack, 2) > 0) 
    % depth first search
    
    % find the best candidate and remove it from the stack 
    % i.e. pop from stack
    [P_parent, problem_stack] = PopFromStack(problem_stack);
    
    % update optima 
    if P_parent.ObjLowerBound >= optimal_solution(2)
        % updated (P_parent's optimal solution is better)
        optimal_solution = [P_parent.ObjUpperBound, P_parent.ObjLowerBound];
    end
    
    % record to optimal history
    optimal_solution_history = SaveOptHistory(optimal_solution_history, P_parent, optimal_solution, debug);

    % P_parent obviously doesnot contain optimum in this case
    if P_parent.ObjUpperBound < optimal_solution(2)
        % P_parent.ObjUpperBound < m* (lower bound of optimum)
        continue;
    end
    
    %  if number of inlier converged, not terminate but continue to next
    %  iteration.
    if P_parent.ObjUpperBound - P_parent.ObjLowerBound < 1
        continue;
    end 
    
    % branch (split) 
    [P_left_child, P_right_child] = SplitProblem(P_parent);
    
    % compute child's cardinality by linear programming
    % left child
    P_left_child = SolveWithLP(p_left, p_right, P_left_child, threshold);
    
    % right child
    P_right_child = SolveWithLP(p_left, p_right, P_right_child, threshold);
    
    if debug
        disp(P_left_child)
        disp(P_right_child)
    end
    
    % who is a better candidate, left child? or right child?
    [P_better, P_worse] = FindBestCandidate([P_left_child, P_right_child]);
    
    % push worse candidate to stack
    problem_stack = PushToStack(problem_stack, P_worse);
    
    % push better candidate to stack
    problem_stack = PushToStack(problem_stack, P_better);
    
    if debug
        disp(P_better)
        disp(P_worse)
        disp(problem_stack)
    end
end