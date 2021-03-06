
% Comparison of Least Squares Monte Carlo with Black Scholes Option Value for European Put Option. Laguirre Polynomials are 
% used as in Longstaff Schwartz (2001) paper. This code is to show why regression functions are not a good fit for option pricing
% at each time steps which is necessary to calculate expected exposure, counter-party credit risk and CVA.


clear;
T = 1.0;            % Time to maturity
r = 0.06;           % risk free rate
sigma = 0.2;        % volatility
K = 40;             % strike price
S0 = 36;            % initial spot price (in the money). For out of money take S0 equal 44.
N = 50;             % number of time steps
M = 1000000;            % number of price paths
k = 3;

dt = T/N;           % value of time step
t = 0:dt:T;         % time vector

z = randn(M/2,1);
w = (r - sigma^2/2)*T + sigma * sqrt(T)* [z;-z];   
S = S0 * exp(w);                                    % price paths generated

P = max(K - S,0);     % payoff at time T

X1 = [];              % vector for storing all (K-S) price paths
C1 = [];              % vector for storing all regression function values
P1 = [];              % vector for storing all the pay off values
S1 = [];              % vector for storing all the generated price paths at each time step

for i = N:-1:2
    
    z = randn(M/2,1);
    w = t(i) * w/t(i+1) + sigma *sqrt(dt*t(i)/t(i+1))*[z;-z];
    S = S0*exp(w);
    
    itmP = find(K - S);      % All paths. For in the money options implement find(K-S>0)
    
    X =  S(itmP);             % All price paths
    
    Y = P(itmP)*exp(-r*dt);  % discounted payoffs
    
    A = BasisFunctions(X,k); % k is the number of basis functions. Check the file BasisFunctions!
    beta = A\Y;              % regression step
    
    C = A * beta;            % Estimated continuation value or the regression values
    E = K - X;               % Intrinsic value
    
    exP = itmP(K - X>0);     % Paths where strike greater than spot
    
    rest = setdiff(1:M,exP);  % Rest of the paths where strike less than spot (needed for american options)
    
    %P(exP) = E(C<E);   % Better to exrcise? Insert value in payoff vector (required for american options)
    
    P(exP) = P(exP)*exp(-r*dt);  %Insert payoffs and discount back one step
    
    u = mean(P * exp(-r*dt));    % Value of the option
    opt_val(i) = u;
    
    X1 = [X1 X];        
    C1 = [C1 C]; 
    P1 = [P1 P]; 
    S1 = [S1 S];

end


% X1_even, C1_even, P1_even, z1_even would collectively store evenly distributed values of X1,C1,P1 and z1 for all i - 1 to 49
X1_even = []; 
C1_even = [];
P1_even = [];
z1_even = [];


for i = 1:1:49
    
    %X_even,C_even,P_even stores evenly distributed values for individual X vectors for a specific set of spot prices
    
    X_even = [];
    C_even = [];
    P_even = [];
    
    %z1 and z2 are the range of z values for +, -  2 standard deviations of the underlying S0
    
    sp = 14;                         % picking 15 values of spot price
    z1 = S0 - 1.96 * std(S1(:,i)) * sqrt(T - i * dt);     
    z2 = S0 + 1.96 * std(S1(:,i)) * sqrt(T - i * dt);
    z = z1:(z2 - z1)/sp:z2;                            
    
    for j = 1:length(z)
    
        X_even = [X_even ; X1(j,i)];
        C_even = [C_even ; C1(j,i)];
        P_even = [P_even ; P1(j,i)];
        
        
    end
    
    X1_even = [X1_even X_even];
    C1_even = [C1_even C_even];
    P1_even = [P1_even P_even];
    z1_even = [z1_even z'];
end
  

% Calculate the initial option value from black scholes formula

[Call,Put] = blsprice(S0,K,r,T,sigma);    % initial option price at time = 0

%Generating regression and spot prices plot for each specific time step after sorting. Time step ranges from 1-49.

X1_even_sort = sort(X1_even(:,45),'ascend');     % X1_even spot price at time step 45
C1_even_sort = sort(C1_even(:,45),'descend');    % C1_even regression values at time step 45
title('European Put Option vs Spot Price','Fontsize',15,'Fontweight','bold','Color','k');
%scatter(X1_even(:,45),C1_even(:,45),35,'b');    % scatter plot if needed
plot(X1_even_sort,C1_even_sort,'-o');            % line plot
xt = get(gca, 'XTick');                          % XTick and YTicks and font size
yt = get(gca, 'YTick');
set(gca, 'FontSize', 12)
hold on

%{ 
The following code will generate plots regression values and black scholes values for different spot 
spot prices at individual specific time steps. So we can have plots for each mentioned time step.The following 
is an example for time step 45.

%}


Put1 = [];               % vector stores all the Black Scholes option values at different time steps
Put_Col = [];
[Call,Put] = blsprice(X1_even(:,45),40,.06,(T - 45 * dt),.2);   % Black Scholes value at time step 45
Put_sort = sort(Put,'descend');
plot(X1_even_sort, Put_sort,'-*');          % Black Scholes option values vs spot price plot for time step 45
xlabel('Spot Price')
ylabel('Option Value')
hold off
legend('Regression Function','Black Scholes Value');
diff = abs(Put_sort - C1_even_sort);                   % absolute error between black scholes and regression values
err = sum(diff);                                       % total error

%{-------------------------------------------------------------------------------------------------------------%}

%{ 
The following code will generate plots regression values and black scholes values for different spot 
spot prices at all time steps in one plot. So we can have a single plot for T = 1. This one is not recommended and 
does not provide too much insights.
%}

%{

Put1 = [];
Put_Col = [];

for iCol = 1:1:49                           % all columns of X1 
    Put_Col = [];                           % initialize a temp column to store intermediate results
    for iRow = 1:1:M                        % M rows of X1

        %X1(iRow, iCol) takes all values of X1 
        %iCol *dt updates t for each colum of X1. for column1 T-dt, for
        %col2 T-2dt ... and so on 
        [Call,Put] = blsprice(X1_even(iRow,iCol),40,.06,T-iCol*dt,.2);    %blsprice(X,K,r,T,sigma)
    
        Put_Col = [Put_Col; Put]; 
        
    end 
    Put1 = [Put1 Put_Col]; 
end 



for i = 1:1:49
    scatter(X1_even(:,i),C1_even(:,i),5,'k');
    title('European Put Option vs Spot Price','Fontsize',12,'Fontweight','bold','Color','k');
    axis([23 55 -0.5 14]);
    xt = get(gca, 'XTick');
    yt = get(gca, 'YTick');
    set(gca, 'FontSize', 12)
    hold on
    scatter(X1_even(:,i),Put1(:,i),5,'r');
    
end

%}

%{ ---------------- end of program --------------------------------- end of program --------------------------------- %}



