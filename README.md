# Household Model Demo
* this demo can run on a PC as it uses only 1 draw when calculating the EMAX matrix
* the model also uses a smoothing algorithm for the EMAX values to compensate for the use of 1 draw.

## Build
* make sure python is installed
* clone the repo from GitHub: `git clone https://github.com/osnatlif/household_model_demo.git`
* from inside the directory, install all python dependencies: `pip install -r requirements.txt`
* build Cython files: `python setup.py build_ext --inplace`
> Note: due to dependencies the Cython build may fail the first time, if this is happening run it again and it should succeed

## Run
* to see all options for running the program run: `python dynamic_model.py -h`. this should give the following options:
```
usage: dynamic_model.py
        -s --static: do not calculate emax
        -m --moments: display moments
        -d --dump-emax: dump emax matrices into files
        -c --cohort: cohort. e.g. 1970white
        -v --verbose
```
* in the demo we have one input file "1970white", to run program on this cohort: ` python dynamic_model.py -c 1970white`

## Project

### Per Cohort Files
these files are under the `input` directory. 
* the per-cohort parameter file is a python file and its name must start with "parameters" and then followed by the name of the cohort. 
for example `parameters1970white.py`
* the per-cohort moments files are (for the "1970white" cohort)
  * `assortative1970white.txt` - assortative mating matrix - 5X5 matrix - 5 levels of education for husband by 5 levels of education for wife
  * `kids_distribution_m1970white.txt` - kids distribution of married women - 21X7 matrix - columns: cohort, race, age, % of no children, % of 1 child, % of 2 children, % of 3+ children
  * `kids_distribution_um1970white.txt` - kids distribution of unmarried women - 21X7 matrix - columns: cohort, race, age, % of no children, % of 1 child, % of 2 children, % of 3+ children                                                                                                                                                
  * `married_h1970white.txt` - husbands (married men) moments - 36X8 - columns: cohort, race, age,employment, # of kids, annual wage, full-time, part-time 
  * `married_w1970white.txt`- wives (married women) moments - 36X8 - columns: cohort, race, age,employment, # of kids, annual wage, full-time, part-time
  * `marr_divorce1970white.txt` - marriage and divorce rate moments- 36X5 - columns: cohort, race, age, marriage rate, divorce rate
  * `school_h1970white.txt` - men's schooling distribution 5 levels - 14X8 - columns: cohort, race, age, HSD rate, HSG rate, SC rate, CG rate, PC rate
  * `school_w1970white.txt`- women's schooling distribution 5 levels - 14X8 - columns: cohort, race, age, HSD rate, HSG rate, SC rate, CG rate, PC rate
  * `unmarried_h1970white.txt`- single men moments - 36X8 - columns: cohort, race, age,employment, # of kids, annual wage, full-time, part-time
  * `unmarried_w1970white.txt`- single women moments - 36X8 - columns: cohort, race, age,employment, # of kids, annual wage, full-time, part-time

### Tax Files
* `deductions_exemptions.out` - by year:  deduction married, deduction single, exemption married, exemption single, exemption per child, EITC no children, EITC 1 child, EITC 2 children, EITC 3 children
* `tax_brackets.out` - by years tax brackets - columns 2-16 - tax brackets values, columns 17-27 tax rate by brackets 

### Python Files
* `cohorts.py` - just holding the "cohort" global variable
* `dynamic_model.py` - the main file of the project. calculating the EMAX matrix and then using it to run the forward simulation
* `forward_simulation.py` - calculate the simulated moments for the 5000 draws
* `moments.py` - defines, calculate and present the moments accumulated during the forward simulation
* `parameters.py` - project parameters that are not per cohort                                                                                                                                                                    
* `setup.py` - controls the Cython build. should be modified only if new Cython files are added to the project

### Cython Files
* `calculate_emax.pyx` - calculate EMAX for single men, single women and married couples
* `calculate_utility_married.pyx` - calculate the current utility function of married individuals - men and women
* `calculate_utility_single_men.pyx` - calculate the current utility function of single men                                                                                                                                                 
* `calculate_utility_single_women.pyx`- calculate the current utility function of single women 
* `calculate_wage.pyx` - calculate wages and job offer probabilities 
* `constant_parameters.pyx` - defines model's constants
* `draw_husband.pyx` - create the "husband" object and initialize it
* `draw_wife.pyx`- create the "wife" object and initialize it
* `gross_to_net.pyx` - calculate net wages using gross wages and the tax files                                                                                                                                                                 
* `married_couple_emax.pyx` - fill the married individuals EMAX matrix
* `meeting_partner.pyx` - calculate probability of meeting a partner by age 
* `single_men.pyx` - fill the single men EMAX matrix                                                                                                                                                                 
* `single_women.pyx` - fill the single women EMAX matrix
* `update_wife_husband_objects.pyx` - update both the husband and the wife objects at the end of each period in the forward solving
* `value_to_index.pyx` - discretization of values - translate values to the grid's indexes
* `randn.cc` - this is actually a C file (not Cython) holding basic math functions that are the most performance sensitive
> Note: after changing any `pxd` or `pyx` files, the Cython build must be run: `python setup.py build_ext --inplace`
