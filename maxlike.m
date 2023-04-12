function [mu,sigma] = maxlike(startmu,startsigma,levels,answers)
% Maximum likelihood for equal loudness measurements
%
% FORMAT   : [mu,sigma] = maxlike(startmu,startsigma,levels,answers)
%
% FUNCTION : Estimates the mean and standard deviation from 
%            and equal-loudness listening test using
%	         maximum-likelihood estimation. 
%
% INPUT    : startmu is the startvalue for the mean estimation.
%	       : startsigma is the startvalue for the standard deviation
%	         estimation.
%	       : levels is a vector containing the presented levels.
%	       : answers is a vector containing answer from the subject:
%            0 for level < reference level, 1 for level > reference level.
%
% OUTPUT   : mu is the estimated mean.
%	       : sigma is the estimated standard deviation.
%
% AUTHOR   : Christian Sejer Pedersen
% DATE	   : 05/06-2001
% MODIFIED : 17/04-2018	
mu_resolution=0.1;
sigma_resolution=0.2;
max_sigma_fit=10;
meanlevel=round(mean(levels));
idx=1;
for mu=meanlevel-10:mu_resolution:meanlevel+10    %should be optimized
	for n=1:length(levels);
		if answers(n) ~=0
			p(n) = normcdf(levels(n),mu,startsigma);
		else
			p(n) = 1-normcdf(levels(n),mu,startsigma);
		end
	end
        %ptotal(mu) = prod(p);
        ptotal(idx,1) = prod(p);
        ptotal(idx,2) = mu;
        idx=idx+1;
end

%ptotal%test
[pmax,mumax_idx] = max(ptotal(:,1));
mumax=ptotal(mumax_idx,2);
clear ptotal
idx=1;
for sigma=sigma_resolution:sigma_resolution:max_sigma_fit
	for n=1:length(levels)
		if answers(n) ~=0
			p(n) = normcdf(levels(n),mumax,sigma);
		else
			p(n) = 1-normcdf(levels(n),mumax,sigma);
		end
	end
	%ptotal(sigma) = prod(p);
    ptotal(idx,1) = prod(p);
    ptotal(idx,2) = sigma;
    idx=idx+1;
end
%ptotal %test
%[pmax,sigmamax] = max(ptotal);
[pmax,sigmamax_idx] = max(ptotal(:,1));
sigmamax=ptotal(sigmamax_idx,2);

clear ptotal
idx=1;
for mu=meanlevel-10:mu_resolution:meanlevel+10    %should be optimized
	for n=1:length(levels);
		if answers(n) ~=0
			p(n) = normcdf(levels(n),mu,sigmamax);
		else
			p(n) = 1-normcdf(levels(n),mu,sigmamax);
		end
	end
        %ptotal(mu) = prod(p);
        ptotal(idx,1) = prod(p);
        ptotal(idx,2) = mu;
        idx=idx+1;
end

%ptotal%test
[pmax,mumax_idx] = max(ptotal(:,1));
mumax=ptotal(mumax_idx,2);
clear ptotal
idx=1;
for sigma=sigma_resolution:sigma_resolution:max_sigma_fit
	for n=1:length(levels)
		if answers(n) ~=0
			p(n) = normcdf(levels(n),mumax,sigma);
		else
			p(n) = 1-normcdf(levels(n),mumax,sigma);
		end
	end
	%ptotal(sigma) = prod(p);
    ptotal(idx,1) = prod(p);
    ptotal(idx,2) = sigma;
    idx=idx+1;
end
%ptotal %test
%[pmax,sigmamax] = max(ptotal);
[pmax,sigmamax_idx] = max(ptotal(:,1));
sigmamax=ptotal(sigmamax_idx,2);

sigma=sigmamax;
mu=mumax;