# ABO Paramter Oracle for Online Portfilio Selection (OLPS) 

This code implements [Adaptive Bayesian Optimization (ABO)](https://www.github.com/fmnyikosa/abo_matlab) with [Steve Hoi's](https://www.smu.edu.sg/faculty/profile/110831/Steven-HOI) [Online Portfolio Selection (OLPS) toolbox](https://github.com/OLPS/OLPS). OLPS is an open-source toolbox for On-Line Portfolio Selection, which includes a collection of classical and state-of-the-art on-line portfolio selection strategies implemented in Matlab/Octave. This codebase adds the ability to adaptively tune the parameters of various trading algorithms as they execute and can be used to test if this produces better performance.

## Setup

The root folder contains the file `start.m` which adds the relevent dependencies to the current path. Make sure you run this file before executing anything. 

The root folder also contains demo files for how to use the various features, and the methods have comments about their inputs and outputs.   

# References

This toolbox includes software developed at the SMU for the following papers:

- Favour M. Nyikosa. Adaptive Configuration Oracle for Online Portfolio Selection Methods (2018). Technical Report, Oxford-MAN Institute of Quantitative Finance, Oxford University.
- Bin Li, Doyen Sahoo, and Steven C.H. Hoi. (2015) "OLPS: A Toolbox for On-Line Portfolio Selection." Singapore Management University.
- Bin Li and Steven C.H. Hoi. (2014) "Online portfolio selection: A Survey." ACM Computing Surveys (CSUR), 46(35), 35:1--35:36.

Please cite the works above for any software or research article that utilizes contributions of this work.

