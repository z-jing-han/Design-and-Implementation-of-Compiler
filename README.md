# Design-and-Implementation-of-Compiler

||Topic|
|:-:|:-:|
|Project 1|Lex Scanner|
|Project 2|Yacc Parser|

Each folder contains two subdirectories: `spec/`, `todo/` and `testfile`.

+ The `spec/` folder contains the problem specifications.

+ The `todo/` folder contains the solution ideas and implementation files.
    + `doto/show_result.py` show the visualization of the project result.

+ The `testfile/` folder contains testcase (both provided and created-self)

## Environment

```
# Environment
conda create -n compiler-env -f environment.yaml
conda activate compiler-env

# Project1
cd Project1/todo
make
./B093040003 < ../testcase/test1.java

# Project2
cd Project2/todo
make
./calc < ../testcase/test1.java

```

